import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../history/views/history_view.dart';
import '../../home/views/home_view.dart';
import '../../reports/views/reports_view.dart';
import '../../settings/views/settings_view.dart';
import '../controllers/main_shell_controller.dart';
import '../widgets/app_bottom_nav.dart';

class MainShellView extends GetView<MainShellController> {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.tab.value;
      return PopScope(
        canPop: tab == MainTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.handleBack();
        },
        child: Scaffold(
          body: IndexedStack(
            index: tab.index,
            children: const [HomeView(), HistoryView(), ReportsView(), SettingsView()],
          ),
          bottomNavigationBar: AppBottomNav(
            current: tab,
            onSelect: (t) {
              HapticFeedback.selectionClick();
              controller.changeTab(t);
            },
            onScan: controller.startScan,
          ),
        ),
      );
    });
  }
}
