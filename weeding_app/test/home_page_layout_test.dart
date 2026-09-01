import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:weeding_app/app/modules/auth/auth_controller.dart';
import 'package:weeding_app/app/modules/home/home_controller.dart';
import 'package:weeding_app/app/modules/home/home_page.dart';
import 'package:weeding_app/app/modules/navigation/main_navigation_controller.dart';
import 'package:weeding_app/app/modules/subscription/subscription_controller.dart';

class _FakeHomeController extends HomeController {
  // Le vrai contrôleur ouvre des canaux Realtime : inutile pour la mise en page.
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  // ignore: must_call_super
  void onClose() {}
  @override
  Future<void> loadStats() async {}
}

class _FakeAuthController extends AuthController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  // ignore: must_call_super
  void onClose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });

  setUp(() {
    Get.put<AuthController>(_FakeAuthController());
    Get.put<HomeController>(_FakeHomeController());
    Get.put(MainNavigationController());
    Get.put(SubscriptionController());
  });

  tearDown(Get.reset);

  const sizes = <Size>[
    Size(320, 568 - 88), // iPhone SE 1re gen
    Size(360, 640 - 88), // Android compact
    Size(390, 844 - 88), // iPhone 14
    Size(412, 915 - 88), // Pixel 7
  ];

  for (final size in sizes) {
    testWidgets('pas de débordement en ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 47)),
          child: MaterialApp(home: HomePage()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);

      // Le contenu ne doit pas défiler : rien à faire glisser.
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, 0);
    });
  }
}
