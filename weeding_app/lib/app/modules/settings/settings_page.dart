import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/shared_components.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/repositories/wedding_settings_repository.dart';
import '../auth/auth_controller.dart';
import '../../routes/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  WeddingSettings? _weddingSettings;
  bool _isLoadingWedding = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
    _loadWeddingSettings();
  }

  Future<void> _loadWeddingSettings() async {
    final settings = await WeddingSettingsRepository().getSettings();
    if (mounted) {
      setState(() {
        _weddingSettings = settings;
        _isLoadingWedding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'Paramètres',
            showBack: false,
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.dark,
                size: 22,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Card ──
                  FadeInSlide(
                    duration: const Duration(milliseconds: 400),
                    child: Obx(() {
                      final profile = authController.profile.value;
                      final name = profile?.fullName ?? 'Admin';
                      final initials = name
                          .split(' ')
                          .map((e) => e.isNotEmpty ? e[0] : '')
                          .join()
                          .toUpperCase();
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.dark,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dark.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              initials: initials.length >= 2
                                  ? initials.substring(0, 2)
                                  : initials,
                              radius: 28,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: 0.15,
                              ),
                              child: Text(
                                initials.length >= 2
                                    ? initials.substring(0, 2)
                                    : initials,
                                style: AppTextStyles.titleLg.copyWith(
                                  color: AppColors.primary,
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Admin',
                                      style: AppTextStyles.labelMd.copyWith(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // ── Wedding Info Card ──
                  FadeInSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _buildWeddingInfoCard(context),
                  ),

                  const SizedBox(height: 8),

                  // ── General Section ──
                  FadeInSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _SettingsSection(
                      title: 'GÉNÉRAL',
                      items: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.dark,
                          title: 'Modifier le profil',
                          onTap: () {},
                        ),
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.dark,
                          title: 'Notifications',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // ── Wedding Section ──
                  FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: _SettingsSection(
                      title: 'MARIAGE',
                      items: [
                        _SettingsTile(
                          icon: Icons.qr_code_2_rounded,
                          iconColor: AppColors.dark,
                          title: 'QR d\'entrée de la salle',
                          subtitle: 'Générer et suivre les arrivées',
                          onTap: () => Get.toNamed(AppRoutes.entranceQr),
                        ),
                        _SettingsTile(
                          icon: Icons.storage_rounded,
                          iconColor: AppColors.dark,
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
                    delay: const Duration(milliseconds: 400),
                    child: _SettingsSection(
                      title: 'COMPTE',
                      items: [
                        _SettingsTile(
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.dark,
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
        ],
      ),
    );
  }

  Widget _buildWeddingInfoCard(BuildContext context) {
    if (_isLoadingWedding) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final s = _weddingSettings;
    final title = s?.title ?? 'Mariage';
    final bride = s?.brideName ?? '';
    final groom = s?.groomName ?? '';
    final location = s?.location ?? 'Non défini';
    final date = s?.eventDate;
    final dateStr = date != null
        ? DateFormat('d MMMM yyyy', 'fr_FR').format(date)
        : 'Non définie';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '💒 $title',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.dark,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          if (bride.isNotEmpty || groom.isNotEmpty)
            Text(
              '$bride & $groom',
              style: AppTextStyles.bodyMdOnVariant.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),

          const Divider(height: 24),

          _WeddingInfoRow(
            icon: Icons.calendar_today_rounded,
            iconColor: AppColors.dark,
            label: 'Date',
            value: dateStr,
          ),
          const SizedBox(height: 12),
          _WeddingInfoRow(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.dark,
            label: 'Lieu',
            value: location,
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditWeddingSheet(context),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Modifier les informations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dark,
                side: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditWeddingSheet(BuildContext context) async {
    final s = _weddingSettings;
    final titleCtrl = TextEditingController(text: s?.title ?? '');
    final brideCtrl = TextEditingController(text: s?.brideName ?? '');
    final groomCtrl = TextEditingController(text: s?.groomName ?? '');
    final locationCtrl = TextEditingController(text: s?.location ?? '');
    DateTime? selectedDate = s?.eventDate;
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.dark.withValues(alpha: 0.48),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.6,
            maxChildSize: 0.96,
            expand: false,
            builder: (ctx, scrollController) => DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Modifier le mariage',
                            style: AppTextStyles.headlineMd,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: titleCtrl,
                            label: 'Titre du mariage',
                            icon: Icons.favorite_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: brideCtrl,
                            label: 'Nom de la mariée',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: groomCtrl,
                            label: 'Nom du marié',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: locationCtrl,
                            label: 'Lieu de la cérémonie',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                border: Border.all(
                                  color: AppColors.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 20,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    selectedDate != null
                                        ? DateFormat(
                                            'd MMMM yyyy',
                                            'fr_FR',
                                          ).format(selectedDate!)
                                        : 'Sélectionner la date',
                                    style: AppTextStyles.bodyMd.copyWith(
                                      color: selectedDate != null
                                          ? AppColors.onSurface
                                          : AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setSheetState(() => isSaving = true);
                                  try {
                                    await WeddingSettingsRepository()
                                        .updateSettings(
                                          title: titleCtrl.text.trim(),
                                          brideName: brideCtrl.text.trim(),
                                          groomName: groomCtrl.text.trim(),
                                          location: locationCtrl.text.trim(),
                                          eventDate: selectedDate,
                                        );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _loadWeddingSettings();
                                    if (mounted) {
                                      Get.snackbar(
                                        'Succès',
                                        'Informations du mariage mises à jour',
                                      );
                                    }
                                  } catch (_) {
                                    if (ctx.mounted) {
                                      setSheetState(() => isSaving = false);
                                    }
                                    if (mounted) {
                                      Get.snackbar(
                                        'Erreur',
                                        'Impossible de modifier le mariage',
                                      );
                                    }
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    titleCtrl.dispose();
    brideCtrl.dispose();
    groomCtrl.dispose();
    locationCtrl.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
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
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wedding Info Row ──
class _WeddingInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _WeddingInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(value, style: AppTextStyles.bodyLg),
            ],
          ),
        ),
      ],
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
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
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
                color: AppColors.surfaceContainerHigh,
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
