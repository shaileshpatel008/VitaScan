extension StringX on String {
  String get capitalized => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  int? get asInt => int.tryParse(trim());
  double? get asDouble => double.tryParse(trim());
}
