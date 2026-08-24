import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../auth/auth_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Paramètres', style: AppTextStyles.headlineMdPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Obx(() {
              final profile = authController.profile.value;
              return Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryFixed,
                        child: Text(
                          profile?.fullName.substring(0, 2).toUpperCase() ?? 'AD',
                          style: AppTextStyles.titleLgPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.fullName ?? 'Admin',
                              style: AppTextStyles.titleLg,
                            ),
                            Text(
                              'Admin',
                              style: AppTextStyles.bodyMdOnVariant,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
                    ],
                  ),
                ),
              );
            }),

            // Settings items
            _SettingsSection(
              title: 'Général',
              items: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Modifier le profil',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.language,
                  title: 'Langue',
                  subtitle: 'Français',
                  onTap: () {},
                ),
              ],
            ),

            _SettingsSection(
              title: 'Mariage',
              items: [
                _SettingsTile(
                  icon: Icons.favorite_outline,
                  title: 'Informations du mariage',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.qr_code_2,
                  title: 'Format des QR codes',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.storage,
                  title: 'Stockage utilisé',
                  onTap: () {},
                ),
              ],
            ),

            _SettingsSection(
              title: 'Compte',
              items: [
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Changer le mot de passe',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Déconnexion',
                  textColor: AppColors.error,
                  onTap: () => _confirmLogout(context, authController),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(4),
    );
  }

  void _confirmLogout(BuildContext context, AuthController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.logout();
            },
            child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 4) return; // déjà sur settings
        final routes = ['/home', '/guests', '/tables', '/invitations', '/settings'];
        Get.offAllNamed(routes[index]);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          activeIcon: Icon(Icons.home, fill: 1.0),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          activeIcon: Icon(Icons.group, fill: 1.0),
          label: 'Invités',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.table_restaurant),
          activeIcon: Icon(Icons.table_restaurant, fill: 1.0),
          label: 'Tables',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_2),
          activeIcon: Icon(Icons.qr_code_2, fill: 1.0),
          label: 'Invitations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          activeIcon: Icon(Icons.more_horiz, fill: 1.0),
          label: 'Plus',
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text(
            title,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.onSurfaceVariant),
      title: Text(
        title,
        style: AppTextStyles.bodyLg.copyWith(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.bodyMdOnVariant) : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.outlineVariant),
      onTap: onTap,
    );
  }
}
