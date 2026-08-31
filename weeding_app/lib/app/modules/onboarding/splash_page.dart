import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../auth/auth_controller.dart';

/// Écran d'arbitrage au démarrage.
///
/// L'application s'ouvrait à froid sur le formulaire de connexion, y compris
/// pour un visiteur qui découvrait le produit. Le splash attend que la session
/// soit restaurée puis oriente : page de garde, onboarding ou tableau de bord.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// En dessous, l'écran ne fait que clignoter au lieu d'annoncer la marque.
  static const _minimumDisplay = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final auth = Get.find<AuthController>();
    final startedAt = DateTime.now();

    if (!auth.isInitialized.value) {
      await auth.isInitialized.stream.firstWhere((ready) => ready);
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minimumDisplay) {
      await Future.delayed(_minimumDisplay - elapsed);
    }
    if (!mounted) return;

    Get.offAllNamed(
      auth.isLoggedIn ? auth.authenticatedEntryRoute : AppRoutes.welcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.dark, width: 1.3),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 44,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Mon Mariage',
              style: AppTextStyles.headlineLg.copyWith(color: AppColors.dark),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
