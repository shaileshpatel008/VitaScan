import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class ConsentController extends GetxController {
  ConsentController(this._settings, this._users, this._permissions);

  final SettingsRepository _settings;
  final UserRepository _users;
  final PermissionService _permissions;

  final acceptedEstimate = false.obs;
  final acceptedTerms = false.obs;
  final busy = false.obs;

  bool get canContinue => acceptedEstimate.value && acceptedTerms.value;

  Future<void> continueTapped() async {
    if (!canContinue) {
      AppMessenger.warning(AppStrings.consentNeedBoth, title: 'One more step');
      return;
    }
    busy.value = true;
    await _permissions.ensureCamera();
    await _settings.update((s) => s.copyWith(onboardingComplete: true, consentAcceptedAt: DateTime.now()));
    busy.value = false;
    Get.offAllNamed(AppRoutes.main);
    final name = _users.profile.value?.firstName ?? '';
    AppMessenger.success('You\'re all set. Take your first scan whenever you\'re ready.', title: 'Welcome, $name!');
  }

  Future<void> openPrivacyPolicy() => _open(AppConstants.privacyPolicyUrl);

  Future<void> openTerms() => _open(AppConstants.termsUrl);

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) AppMessenger.error(AppStrings.somethingWrong);
  }
}
