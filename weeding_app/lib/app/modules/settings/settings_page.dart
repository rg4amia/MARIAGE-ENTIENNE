import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../core/widgets/shared_components.dart';
import '../auth/auth_controller.dart';
import '../../routes/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Paramètres', style: AppTextStyles.headlineLgMobile),
              ),
              const SizedBox(height: 20),

              // ── Premium Profile Card ──
              FadeInSlide(
                duration: const Duration(milliseconds: 400),
                child: Obx(() {
                  final profile = authController.profile.value;
                  final name = profile?.fullName ?? 'Admin';
                  final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, Color(0xFFD4592A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          initials: initials.length >= 2 ? initials.substring(0, 2) : initials,
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            initials.length >= 2 ? initials.substring(0, 2) : initials,
                            style: AppTextStyles.titleLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.titleLg.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Admin',
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // ── General Section ──
              FadeInSlide(
                delay: const Duration(milliseconds: 100),
                child: _SettingsSection(
                  title: 'GÉNÉRAL',
                  items: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primaryContainer,
                      title: 'Modifier le profil',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.secondaryContainer,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.tertiaryContainer,
                      title: 'Langue',
                      trailing: Text(
                        'Français',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // ── Wedding Section ──
              FadeInSlide(
                delay: const Duration(milliseconds: 200),
                child: _SettingsSection(
                  title: 'MARIAGE',
                  items: [
                    _SettingsTile(
                      icon: Icons.favorite_outline_rounded,
                      iconColor: AppColors.primaryContainer,
                      title: 'Informations du mariage',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.qr_code_2_rounded,
                      iconColor: AppColors.secondaryContainer,
                      title: 'QR d\'entrée de la salle',
                      subtitle: 'Générer et suivre les arrivées',
                      onTap: () => Get.toNamed(AppRoutes.entranceQr),
                    ),
                    _SettingsTile(
                      icon: Icons.storage_rounded,
                      iconColor: AppColors.tertiaryContainer,
                      title: 'Stockage utilisé',
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.outlineVariant,
                        size: 20,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              // ── Account Section ──
              FadeInSlide(
                delay: const Duration(milliseconds: 300),
                child: _SettingsSection(
                  title: 'COMPTE',
                  items: [
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.tertiaryContainer,
                      title: 'Changer le mot de passe',
                      onTap: () {},
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      title: 'Déconnexion',
                      titleColor: AppColors.error,
                      onTap: () => _confirmLogout(context, authController),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── App version ──
              Center(
                child: Text(
                  'Wedding App v1.0.0',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }

  void _confirmLogout(BuildContext context, AuthController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: AppTextStyles.bodyMd),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.logout();
            },
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Section ──
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: items),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Settings Tile ──
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.outlineVariant,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
