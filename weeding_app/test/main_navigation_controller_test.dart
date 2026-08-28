import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/modules/navigation/main_navigation_controller.dart';

void main() {
  group('MainNavigationController', () {
    test('change l’onglet sans créer une nouvelle route', () {
      final controller = MainNavigationController();

      controller.selectTab(MainNavigationController.tablesTab);

      expect(controller.currentIndex.value, MainNavigationController.tablesTab);
    });

    test('ignore un index hors de la barre centrale', () {
      final controller = MainNavigationController();

      controller.selectTab(-1);
      controller.selectTab(5);

      expect(controller.currentIndex.value, MainNavigationController.homeTab);
    });
  });
}
