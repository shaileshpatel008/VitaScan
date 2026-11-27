import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../data/datasources/local_datasource.dart';
import '../utils/app_logger.dart';
import '../utils/review_policy.dart';

/// Asks happy users for a Play Store rating using Google's in-app review
/// dialog (the user never leaves the app), and opens the store listing from
/// Settings → Rate Wellumi.
class ReviewService extends GetxService {
  ReviewService(this._local);

  final LocalDataSource _local;
  final _review = InAppReview.instance;

  int _goodScans = 0;
  int _timesAsked = 0;
  DateTime? _lastAskedAt;

  ReviewService init() {
    final m = _local.readReviewPrompt() ?? const {};
    _goodScans = m['goodScans'] as int? ?? 0;
    _timesAsked = m['timesAsked'] as int? ?? 0;
    _lastAskedAt = DateTime.tryParse(m['lastAskedAt'] as String? ?? '');
    return this;
  }

  /// Call when a fresh scan result is shown. Returns true if the review dialog
  /// was requested, so the caller can skip other pop-ups.
  Future<bool> onScanResult({required int? signalQuality, required bool needsAttention}) async {
    if (!ReviewPolicy.isGoodResult(signalQuality: signalQuality, needsAttention: needsAttention)) return false;
    _goodScans++;
    final now = DateTime.now();
    final ask = ReviewPolicy.shouldAsk(
      goodScans: _goodScans,
      timesAsked: _timesAsked,
      lastAskedAt: _lastAskedAt,
      now: now,
    );
    if (ask) {
      _timesAsked++;
      _lastAskedAt = now;
    }
    await _save();
    if (!ask) return false;
    try {
      if (!await _review.isAvailable()) return false;
      await _review.requestReview();
      return true;
    } catch (e, st) {
      AppLogger.error('In-app review failed', e, st);
      return false;
    }
  }

  /// Settings → Rate Wellumi. Always opens the Play Store page.
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing();
    } catch (e, st) {
      AppLogger.error('Opening store listing failed', e, st);
    }
  }

  Future<void> _save() => _local.writeReviewPrompt({
    'goodScans': _goodScans,
    'timesAsked': _timesAsked,
    'lastAskedAt': _lastAskedAt?.toIso8601String(),
  });
}
