import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:wellumi/core/constants/app_constants.dart';
import 'package:wellumi/core/services/purchase_service.dart';
import 'package:wellumi/core/utils/premium_policy.dart';
import 'package:wellumi/routes/app_routes.dart';
import 'package:wellumi/routes/scan_gate_middleware.dart';

class _FakePurchases extends GetxService implements PurchaseService {
  _FakePurchases({required this.used, this.premium = false});
  final int used;
  final bool premium;

  @override
  ScanAllowance get allowance => ScanAllowance(used: used, isPremium: premium);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ScanAllowance', () {
    test('3 free scans, then blocked', () {
      expect(const ScanAllowance(used: 0, isPremium: false).remaining, 3);
      expect(const ScanAllowance(used: 2, isPremium: false).canScan, isTrue);
      expect(const ScanAllowance(used: 2, isPremium: false).isLastFreeScan, isTrue);
      expect(const ScanAllowance(used: 3, isPremium: false).canScan, isFalse);
      expect(const ScanAllowance(used: 5, isPremium: false).remaining, 0);
    });

    test('Premium is unlimited', () {
      const a = ScanAllowance(used: 40, isPremium: true);
      expect(a.canScan, isTrue);
      expect(a.isLastFreeScan, isFalse);
    });
  });

  group('PremiumPlan', () {
    test('maps product IDs', () {
      expect(PremiumPlan.fromProductId(AppConstants.premiumMonthlyId), PremiumPlan.monthly);
      expect(PremiumPlan.fromProductId(AppConstants.premiumYearlyId), PremiumPlan.yearly);
      expect(PremiumPlan.fromProductId(AppConstants.premiumLifetimeId), PremiumPlan.lifetime);
      expect(PremiumPlan.fromProductId('something_else'), PremiumPlan.none);
    });

    test('best owned plan wins; nothing owned means not premium', () {
      expect(
        PremiumPlan.fromOwned([AppConstants.premiumMonthlyId, AppConstants.premiumLifetimeId]),
        PremiumPlan.lifetime,
      );
      expect(PremiumPlan.fromOwned([AppConstants.premiumMonthlyId]), PremiumPlan.monthly);
      expect(PremiumPlan.fromOwned(const []), PremiumPlan.none);
      expect(PremiumPlan.fromOwned(const []).isActive, isFalse);
    });

    test('subscription vs lifetime', () {
      expect(PremiumPlan.yearly.isSubscription, isTrue);
      expect(PremiumPlan.lifetime.isSubscription, isFalse);
    });
  });

  test('billing period labels', () {
    expect(billingPeriodLabel('P1M'), 'month');
    expect(billingPeriodLabel('P1Y'), 'year');
    expect(billingPeriodLabel('P1W'), 'week');
    expect(billingPeriodLabel('P3D'), '3 days');
    expect(billingPeriodLabel('bad'), '');
  });

  group('ScanGateMiddleware', () {
    Future<void> openScan(WidgetTester tester, PurchaseService purchases) async {
      Get.testMode = true;
      Get.put<PurchaseService>(purchases);
      await tester.pumpWidget(GetMaterialApp(
        initialRoute: '/home',
        getPages: [
          GetPage(name: '/home', page: () => const Scaffold(body: Text('home'))),
          GetPage(
            name: AppRoutes.scanGuide,
            page: () => const Scaffold(body: Text('scan-guide')),
            middlewares: [ScanGateMiddleware()],
          ),
          GetPage(name: AppRoutes.premium, page: () => const Scaffold(body: Text('premium'))),
        ],
      ));
      Get.toNamed(AppRoutes.scanGuide);
      await tester.pumpAndSettle();
    }

    tearDown(Get.reset);

    testWidgets('free scans left: scan opens', (tester) async {
      await openScan(tester, _FakePurchases(used: 2));
      expect(find.text('scan-guide'), findsOneWidget);
    });

    testWidgets('free scans used: redirected to Premium', (tester) async {
      await openScan(tester, _FakePurchases(used: 3));
      expect(find.text('premium'), findsOneWidget);
      expect(find.text('scan-guide'), findsNothing);
    });

    testWidgets('Premium user: scan opens', (tester) async {
      await openScan(tester, _FakePurchases(used: 10, premium: true));
      expect(find.text('scan-guide'), findsOneWidget);
    });
  });
}
