import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class ProfileSetupController extends GetxController {
  ProfileSetupController(this._users);

  final UserRepository _users;

  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final weightCtrl = TextEditingController();

  final gender = Gender.male.obs;
  final hasHypertension = false.obs;
  final onBpMedication = false.obs;
  final hasDiabetes = false.obs;
  final saving = false.obs;

  /// Opened from Settings → Edit profile.
  late final bool isEditing = Get.arguments == true;

  @override
  void onInit() {
    super.onInit();
    final p = _users.profile.value;
    if (p != null) {
      nameCtrl.text = p.name;
      ageCtrl.text = '${p.age}';
      heightCtrl.text = p.heightCm.toStringAsFixed(0);
      weightCtrl.text = p.weightKg.toStringAsFixed(p.weightKg % 1 == 0 ? 0 : 1);
      gender.value = p.gender;
      hasHypertension.value = p.hasHypertension;
      onBpMedication.value = p.onBpMedication;
      hasDiabetes.value = p.hasDiabetes;
    }
  }

  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) {
      AppMessenger.warning('Please check the highlighted fields.', title: 'A few details are missing');
      return;
    }
    saving.value = true;
    final now = DateTime.now();
    final existing = _users.profile.value;
    final profile = UserProfile(
      name: nameCtrl.text.trim(),
      age: int.parse(ageCtrl.text.trim()),
      gender: gender.value,
      heightCm: double.parse(heightCtrl.text.trim()),
      weightKg: double.parse(weightCtrl.text.trim()),
      hasHypertension: hasHypertension.value,
      onBpMedication: onBpMedication.value,
      hasDiabetes: hasDiabetes.value,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _users.save(profile);
    saving.value = false;

    if (isEditing) {
      Get.back();
      AppMessenger.success(AppStrings.profileSaved, title: 'Profile saved');
    } else {
      Get.toNamed(AppRoutes.consent);
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    super.onClose();
  }
}
