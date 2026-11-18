import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/local_datasource.dart';
import '../../widgets/update_dialog.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../utils/app_logger.dart';
import '../utils/app_messenger.dart';
import '../utils/version_utils.dart';

/// Keeps the app up to date from the stores.
///
/// * Android: Google Play In-App Updates. Optional updates download in the
///   background ("flexible") and the user taps Restart once; required updates
///   (Play priority >= 4, or below the hosted minimum version) use Play's
///   full-screen "immediate" flow.
/// * iOS: Apple has no in-app update API, so we compare with the App Store
///   (iTunes lookup) and open the store page.
class AppUpdateService extends GetxService with WidgetsBindingObserver {
  AppUpdateService(this._local);

  final LocalDataSource _local;
  final _http = GetConnect(timeout: const Duration(seconds: 8));

  final checking = false.obs;
  final version = ''.obs;
  final buildNumber = ''.obs;

  PackageInfo? _info;
  StreamSubscription<InstallStatus>? _installSub;
  bool _dialogOpen = false;

  Future<AppUpdateService> init() async {
    try {
      _info = await PackageInfo.fromPlatform();
      version.value = _info!.version;
      buildNumber.value = _info!.buildNumber;
    } catch (e) {
      AppLogger.error('PackageInfo unavailable', e);
      version.value = AppConstants.appVersion;
    }
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  /// Quiet check at start-up: only shows something when an update exists.
  Future<void> checkOnLaunch() => _check(manual: false);

  /// "Check for updates" in Profile: always gives feedback.
  Future<void> checkManually() => _check(manual: true);

  Future<void> _check({required bool manual}) async {
    if (checking.value) return;
    checking.value = true;
    try {
      final minVersion = await _fetchMinimumVersion();
      if (Platform.isAndroid) {
        await _checkAndroid(manual: manual, minVersion: minVersion);
      } else if (Platform.isIOS) {
        await _checkIos(manual: manual, minVersion: minVersion);
      }
    } catch (e, st) {
      AppLogger.error('Update check failed', e, st);
      if (manual) AppMessenger.warning(AppStrings.updateCheckFailed, title: 'Couldn\'t check');
    } finally {
      checking.value = false;
    }
  }

  // ---------------------------------------------------------------- Android

  Future<void> _checkAndroid({required bool manual, String? minVersion}) async {
    final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } on PlatformException catch (e) {
      // Thrown when the app wasn't installed from Google Play (debug builds,
      // side-loaded APKs). Nothing to do for automatic checks.
      AppLogger.debug('In-app update unavailable: ${e.message}');
      if (manual) AppMessenger.info(AppStrings.updateNotFromStore, title: 'Updates come from Google Play');
      return;
    }

    if (info.installStatus == InstallStatus.downloaded) {
      await _promptRestart();
      return;
    }
    if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
      // Google requires resuming an interrupted immediate update.
      await InAppUpdate.performImmediateUpdate();
      return;
    }

    final urgency = UpdatePolicy.decide(
      currentVersion: version.value,
      newerAvailable: info.updateAvailability == UpdateAvailability.updateAvailable,
      minSupportedVersion: minVersion,
      playPriority: info.updatePriority,
    );

    switch (urgency) {
      case UpdateUrgency.none:
        if (manual) AppMessenger.success(AppStrings.updateUpToDate, title: 'You\'re up to date');
      case UpdateUrgency.required:
        if (info.immediateUpdateAllowed) {
          final result = await InAppUpdate.performImmediateUpdate();
          // Back-press cancels Play's screen; keep asking because this version is unsupported.
          if (result != AppUpdateResult.success) await _showRequiredDialog(onUpdate: _openStore);
        } else {
          await _showRequiredDialog(onUpdate: _openStore);
        }
      case UpdateUrgency.optional:
        final key = 'android-${info.availableVersionCode ?? 'next'}';
        if (!manual && _isSnoozed(key)) return;
        if (!info.flexibleUpdateAllowed) {
          if (info.immediateUpdateAllowed) await InAppUpdate.performImmediateUpdate();
          return;
        }
        // Play shows its own short consent sheet, then downloads in the background.
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          AppMessenger.info(AppStrings.updateDownloading, title: 'Updating');
          _listenForDownload();
        } else if (result == AppUpdateResult.userDeniedUpdate) {
          await _snooze(key);
        } else {
          AppMessenger.warning(AppStrings.updateFailed, title: 'Update paused');
        }
    }
  }

  void _listenForDownload() {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        _installSub?.cancel();
        _promptRestart();
      } else if (status == InstallStatus.failed) {
        _installSub?.cancel();
        AppMessenger.warning(AppStrings.updateFailed, title: 'Update paused');
      }
    });
  }

  Future<void> _promptRestart() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final restart = await UpdateDialog.show(
      title: AppStrings.updateDownloadedTitle,
      message: AppStrings.updateDownloadedBody,
      primaryLabel: AppStrings.updateRestart,
      icon: UpdateDialogIcon.ready,
    );
    _dialogOpen = false;
    if (restart) await InAppUpdate.completeFlexibleUpdate();
  }

  // ---------------------------------------------------------------- iOS

  Future<void> _checkIos({required bool manual, String? minVersion}) async {
    final bundleId = _info?.packageName;
    if (bundleId == null) return;
    final store = await _lookupAppStore(bundleId);
    if (store == null) {
      // Not published yet, or not available in this country.
      if (manual) AppMessenger.success(AppStrings.updateUpToDate, title: 'You\'re up to date');
      return;
    }

    final urgency = UpdatePolicy.decide(
      currentVersion: version.value,
      newerAvailable: VersionUtils.isOlder(version.value, store.version),
      minSupportedVersion: minVersion,
    );

    switch (urgency) {
      case UpdateUrgency.none:
        if (manual) AppMessenger.success(AppStrings.updateUpToDate, title: 'You\'re up to date');
      case UpdateUrgency.required:
        await _showRequiredDialog(
          onUpdate: () => _launch(store.url),
          notes: store.releaseNotes,
          newVersion: store.version,
        );
      case UpdateUrgency.optional:
        final key = 'ios-${store.version}';
        if (!manual && _isSnoozed(key)) return;
        if (_dialogOpen) return;
        _dialogOpen = true;
        final update = await UpdateDialog.show(
          title: AppStrings.updateTitle,
          message: AppStrings.updateBody,
          primaryLabel: AppStrings.updateNow,
          secondaryLabel: AppStrings.updateLater,
          newVersion: store.version,
          releaseNotes: store.releaseNotes,
        );
        _dialogOpen = false;
        if (update) {
          await _launch(store.url);
        } else {
          await _snooze(key);
        }
    }
  }

  Future<_StoreRelease?> _lookupAppStore(String bundleId) async {
    final country = Get.deviceLocale?.countryCode?.toLowerCase();
    final query = {'bundleId': bundleId, 'country': ?country, 't': '${DateTime.now().millisecondsSinceEpoch}'};
    final res = await _http.get('https://itunes.apple.com/lookup', query: query);
    if (!res.isOk || res.bodyString == null) return null;
    final body = jsonDecode(res.bodyString!) as Map<String, dynamic>;
    final results = body['results'] as List? ?? const [];
    if (results.isEmpty) return null;
    final r = results.first as Map<String, dynamic>;
    final v = r['version'] as String?;
    final url = r['trackViewUrl'] as String?;
    if (v == null || url == null) return null;
    return _StoreRelease(version: v, url: url, releaseNotes: r['releaseNotes'] as String?);
  }

  // ---------------------------------------------------------------- shared

  /// Reads the optional hosted minimum-version file. Failures are ignored so
  /// the app never blocks on it.
  Future<String?> _fetchMinimumVersion() async {
    if (AppConstants.updateConfigUrl.isEmpty) return null;
    try {
      final res = await _http.get(AppConstants.updateConfigUrl);
      if (!res.isOk || res.bodyString == null) return null;
      final json = jsonDecode(res.bodyString!) as Map<String, dynamic>;
      final platform = json[Platform.isIOS ? 'ios' : 'android'];
      final min = (platform is Map ? platform['min_version'] : null) ?? json['min_version'];
      return min?.toString();
    } catch (e) {
      AppLogger.debug('Update config unavailable: $e');
      return null;
    }
  }

  Future<void> _showRequiredDialog({
    required Future<void> Function() onUpdate,
    String? notes,
    String? newVersion,
  }) async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    // Stays until the user updates: this version is no longer supported.
    while (true) {
      await UpdateDialog.show(
        title: AppStrings.updateRequiredTitle,
        message: AppStrings.updateRequiredBody,
        primaryLabel: AppStrings.updateNow,
        newVersion: newVersion,
        releaseNotes: notes,
        forced: true,
      );
      await onUpdate();
      await Future.delayed(const Duration(seconds: 1));
      if (!_dialogOpen) break;
    }
  }

  Future<void> _openStore() async {
    final id = _info?.packageName ?? '';
    await _launch('https://play.google.com/store/apps/details?id=$id');
  }

  Future<void> _launch(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) AppMessenger.error(AppStrings.somethingWrong);
  }

  bool _isSnoozed(String key) {
    final s = _local.readUpdateSnooze();
    if (s == null || s['key'] != key) return false;
    final at = DateTime.tryParse(s['at'] as String? ?? '');
    return at != null && DateTime.now().difference(at).inHours < AppConstants.updateRemindAfterHours;
  }

  Future<void> _snooze(String key) => _local.writeUpdateSnooze({'key': key, 'at': DateTime.now().toIso8601String()});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (Platform.isAndroid) {
      // A background download may have finished, or an immediate update may
      // need resuming, while the app was away.
      InAppUpdate.checkForUpdate()
          .then((info) {
            if (info.installStatus == InstallStatus.downloaded) {
              _promptRestart();
            } else if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
              InAppUpdate.performImmediateUpdate();
            }
          })
          .catchError((_) {});
    } else if (Platform.isIOS && _dialogOpen) {
      // Back from the App Store: re-check, and release the required-update
      // loop once the new version is installed.
      _recheckAfterStore();
    }
  }

  Future<void> _recheckAfterStore() async {
    final info = await PackageInfo.fromPlatform();
    if (info.version != version.value) _dialogOpen = false;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _installSub?.cancel();
    super.onClose();
  }
}

class _StoreRelease {
  const _StoreRelease({required this.version, required this.url, this.releaseNotes});
  final String version;
  final String url;
  final String? releaseNotes;
}
