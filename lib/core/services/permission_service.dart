import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_strings.dart';
import '../utils/app_messenger.dart';

class PermissionService {
  /// Asks for camera access with a friendly explanation first. Returns true
  /// when the camera can be used.
  Future<bool> ensureCamera() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isRestricted) {
      final open = await AppMessenger.confirm(
        title: AppStrings.cameraPermissionTitle,
        message: AppStrings.cameraPermissionDeniedBody,
        confirmText: AppStrings.openSettings,
        cancelText: AppStrings.notNow,
        icon: Icons.photo_camera_outlined,
      );
      if (open) await openAppSettings();
      return false;
    }

    status = await Permission.camera.request();
    if (status.isGranted) return true;
    AppMessenger.warning(AppStrings.cameraPermissionBody, title: AppStrings.cameraPermissionTitle);
    return false;
  }
}
