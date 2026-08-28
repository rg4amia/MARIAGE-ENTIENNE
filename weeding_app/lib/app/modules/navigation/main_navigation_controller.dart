import 'package:get/get.dart';

/// Pilote les cinq onglets principaux sans recréer leurs pages.
class MainNavigationController extends GetxController {
  static const homeTab = 0;
  static const guestsTab = 1;
  static const tablesTab = 2;
  static const invitationsTab = 3;
  static const settingsTab = 4;

  final RxInt currentIndex = homeTab.obs;

  void selectTab(int index) {
    if (index < homeTab || index > settingsTab) return;
    currentIndex.value = index;
  }
}
