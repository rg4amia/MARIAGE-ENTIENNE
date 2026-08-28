import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../guests/guests_page.dart';
import '../home/home_page.dart';
import '../invitations/invitations_page.dart';
import '../settings/settings_page.dart';
import '../tables/tables_page.dart';
import 'main_navigation_controller.dart';

/// Point d'entrée unique de l'espace administrateur.
///
/// L'IndexedStack garde chaque onglet monté : filtres, scroll et formulaires ne
/// sont plus perdus lorsqu'on change de section.
class MainShellPage extends StatefulWidget {
  final int initialIndex;

  const MainShellPage({super.key, this.initialIndex = 0});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _pages = <Widget>[
    HomePage(),
    GuestsPage(),
    TablesPage(),
    InvitationsPage(),
    SettingsPage(),
  ];

  late final MainNavigationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MainNavigationController>();
    _controller.selectTab(widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex = _controller.currentIndex.value;

      return PopScope(
        canPop: currentIndex == MainNavigationController.homeTab,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            _controller.selectTab(MainNavigationController.homeTab);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: IndexedStack(index: currentIndex, children: _pages),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: currentIndex,
            onTabSelected: _controller.selectTab,
          ),
        ),
      );
    });
  }
}
