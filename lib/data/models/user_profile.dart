enum Gender {
  male('Male'),
  female('Female'),
  other('Other');

  const Gender(this.label);
  final String label;

  static Gender fromName(String? name) => Gender.values.firstWhere((g) => g.name == name, orElse: () => Gender.other);
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    this.hasHypertension = false,
    this.onBpMedication = false,
    this.hasDiabetes = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String name;
  final int age;
  final Gender gender;
  final double heightCm;
  final double weightKg;
  final bool hasHypertension;
  final bool onBpMedication;
  final bool hasDiabetes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get bmi {
    final m = heightCm / 100;
    return m <= 0 ? 0 : weightKg / (m * m);
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  UserProfile copyWith({
    String? name,
    int? age,
    Gender? gender,
    double? heightCm,
    double? weightKg,
    bool? hasHypertension,
    bool? onBpMedication,
    bool? hasDiabetes,
    DateTime? updatedAt,
  }) => UserProfile(
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    hasHypertension: hasHypertension ?? this.hasHypertension,
    onBpMedication: onBpMedication ?? this.onBpMedication,
    hasDiabetes: hasDiabetes ?? this.hasDiabetes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'age': age,
    'gender': gender.name,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'hasHypertension': hasHypertension,
    'onBpMedication': onBpMedication,
    'hasDiabetes': hasDiabetes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) => UserProfile(
    name: map['name'] as String? ?? '',
    age: (map['age'] as num?)?.toInt() ?? 30,
    gender: Gender.fromName(map['gender'] as String?),
    heightCm: (map['heightCm'] as num?)?.toDouble() ?? 170,
    weightKg: (map['weightKg'] as num?)?.toDouble() ?? 70,
    hasHypertension: map['hasHypertension'] as bool? ?? false,
    onBpMedication: map['onBpMedication'] as bool? ?? false,
    hasDiabetes: map['hasDiabetes'] as bool? ?? false,
    createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}
