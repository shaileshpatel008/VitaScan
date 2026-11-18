/// Semantic-version helpers ("1.4.2", "1.4.2+17", "v2.0").
class VersionUtils {
  VersionUtils._();

  static List<int> _parts(String v) {
    final core = v.trim().replaceFirst(RegExp(r'^[vV]'), '').split(RegExp(r'[+\-\s]')).first;
    return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  /// Negative if [a] < [b], zero if equal, positive if [a] > [b].
  static int compare(String a, String b) {
    final pa = _parts(a), pb = _parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  static bool isOlder(String current, String other) => compare(current, other) < 0;
}

enum UpdateUrgency { none, optional, required }

/// Decides how strongly to ask for an update.
class UpdatePolicy {
  UpdatePolicy._();

  /// Play Console in-app update priority (0–5) at or above which an update is
  /// treated as required.
  static const int requiredPlayPriority = 4;

  static UpdateUrgency decide({
    required String currentVersion,
    required bool newerAvailable,
    String? minSupportedVersion,
    int playPriority = 0,
  }) {
    final belowMinimum =
        minSupportedVersion != null &&
        minSupportedVersion.isNotEmpty &&
        VersionUtils.isOlder(currentVersion, minSupportedVersion);
    if (belowMinimum) return UpdateUrgency.required;
    if (!newerAvailable) return UpdateUrgency.none;
    if (playPriority >= requiredPlayPriority) return UpdateUrgency.required;
    return UpdateUrgency.optional;
  }
}
