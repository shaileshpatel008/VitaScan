class Validators {
  Validators._();

  static String? name(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Please enter your name';
    if (value.length < 2) return 'Name looks too short';
    return null;
  }

  static String? Function(String?) intRange(String label, int min, int max) => (v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Enter $label';
    if (n < min || n > max) return '$min–$max';
    return null;
  };

  static String? Function(String?) decimalRange(String label, double min, double max) => (v) {
    final n = double.tryParse(v?.trim() ?? '');
    if (n == null) return 'Enter $label';
    if (n < min || n > max) return '${min.toStringAsFixed(0)}–${max.toStringAsFixed(0)}';
    return null;
  };

  /// Wellumi is for adults (matches the Play Console target audience: 18+).
  static String? age(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Enter age';
    if (n < 18) return 'Wellumi is for adults 18+';
    if (n > 110) return '18–110';
    return null;
  }

  static final heightCm = decimalRange('height', 100, 230);
  static final weightKg = decimalRange('weight', 25, 250);
  static final systolic = intRange('systolic', 70, 250);
  static final diastolic = intRange('diastolic', 40, 150);
  static final pulse = intRange('pulse', 30, 220);
}
