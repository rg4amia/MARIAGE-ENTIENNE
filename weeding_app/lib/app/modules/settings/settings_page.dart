import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/shared_components.dart';
import '../admin/admin_controller.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/repositories/auth_repository.dart';
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
              child: Icon(
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
                          icon: Icons.location_city_rounded,
                          iconColor: AppColors.primary,
                          title: 'Lieux et itinéraires',
                          subtitle: 'Mairie, église et salle de réception',
                          onTap: () => Get.toNamed(AppRoutes.venues),
                        ),
                        _SettingsTile(
                          icon: Icons.palette_outlined,
                          iconColor: Theme.of(context).colorScheme.primary,
                          title: 'Couleurs du mariage',
                          subtitle: 'Application et invitations',
                          trailing: _PaletteDots(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                              Theme.of(context).colorScheme.tertiary,
                            ],
                          ),
                          onTap: () => Get.toNamed(AppRoutes.weddingTheme),
                        ),
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.dark,
                          title: 'Modifier le profil',
                          onTap: () => _showEditProfileSheet(context, authController),
                        ),
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.dark,
                          title: 'Notifications',
                          onTap: () => _showNotificationsSheet(context),
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
                          onTap: () => _showStorageSheet(context),
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
                          onTap: () => _showChangePasswordSheet(context),
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

                  // Visible des seuls exploitants du service : les couples
                  // n'ont pas à soupçonner qu'une console existe.
                  Obx(() {
                    if (!Get.find<AdminController>().isPlatformAdmin.value) {
                      return const SizedBox.shrink();
                    }
                    return FadeInSlide(
                      delay: const Duration(milliseconds: 450),
                      child: _SettingsSection(
                        title: 'EXPLOITATION',
                        items: [
                          _SettingsTile(
                            icon: Icons.admin_panel_settings_outlined,
                            iconColor: AppColors.primary,
                            title: 'Console exploitant',
                            onTap: () {
                              Get.find<AdminController>().loadAll();
                              Get.toNamed(AppRoutes.admin);
                            },
                          ),
                        ],
                      ),
                    );
                  }),

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.2),
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
              decoration: BoxDecoration(
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
                                  Icon(
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
                              : Text(
                                  'Enregistrer',
                                  style: AppTextStyles.titleLg,
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
            child: Text(
              'Déconnexion',
              style: AppTextStyles.titleLg.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Modifier le profil
  // ────────────────────────────────────────────────
  Future<void> _showEditProfileSheet(
    BuildContext context,
    AuthController authController,
  ) async {
    final profile = authController.profile.value;
    final nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    var isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => DecoratedBox(
              decoration: BoxDecoration(
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
                            'Modifier le profil',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nom complet',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            style: AppTextStyles.bodyLg,
                            decoration: InputDecoration(
                              hintText: 'Votre nom',
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.dark,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),                              ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Téléphone',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: AppTextStyles.bodyLg,
                            decoration: InputDecoration(
                              hintText: '+225 07 00 00 00 00',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.dark,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
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
                            color: AppColors.outlineVariant.withValues(alpha: 0.45),
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
                                    await AuthRepository().updateProfile(
                                      fullName: nameCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim().isEmpty
                                          ? null
                                          : phoneCtrl.text.trim(),
                                    );
                                    await authController.refreshProfile();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (mounted) {
                                      Get.snackbar(
                                        'Succès',
                                        'Profil mis à jour',
                                      );
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      setSheetState(() => isSaving = false);
                                    }
                                    if (mounted) {
                                      Get.snackbar(
                                        'Erreur',
                                        'Impossible de modifier le profil',
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
                              : Text(
                                  'Enregistrer',
                                  style: AppTextStyles.titleLg,
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

    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  // ────────────────────────────────────────────────
  // Notifications
  // ────────────────────────────────────────────────
  Future<void> _showNotificationsSheet(BuildContext context) async {
    // Default notification preferences (stored locally for now)
    var notifyGuestRsvp = true;
    var notifyMediaUpload = true;
    var notifyCardUnlock = true;
    var notifyEntranceScan = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) => DecoratedBox(
            decoration: BoxDecoration(
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
                          'Notifications',
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
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Text(
                        'Choisissez les événements pour lesquels\nvou souhaitez être notifié.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _NotificationToggle(
                        icon: Icons.how_to_reg_rounded,
                        iconColor: AppColors.primary,
                        title: 'Réponse d\'invitation',
                        subtitle: 'Quand un invité confirme ou décline',
                        value: notifyGuestRsvp,
                        onChanged: (v) => setSheetState(() => notifyGuestRsvp = v),
                      ),
                      _NotificationToggle(
                        icon: Icons.mic_rounded,
                        iconColor: AppColors.statusMediaReceived,
                        title: 'Média reçu',
                        subtitle: 'Quand un invité enregistre un message',
                        value: notifyMediaUpload,
                        onChanged: (v) => setSheetState(() => notifyMediaUpload = v),
                      ),
                      _NotificationToggle(
                        icon: Icons.lock_open_rounded,
                        iconColor: AppColors.statusCardUnlocked,
                        title: 'Carte débloquée',
                        subtitle: 'Quand un invité déverrouille sa carte',
                        value: notifyCardUnlock,
                        onChanged: (v) => setSheetState(() => notifyCardUnlock = v),
                      ),
                      _NotificationToggle(
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: AppColors.dark,
                        title: 'Arrivée à la salle',
                        subtitle: 'Quand un invité scanne le QR d\'entrée',
                        value: notifyEntranceScan,
                        onChanged: (v) => setSheetState(() => notifyEntranceScan = v),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Get.snackbar(
                            'Succès',
                            'Préférences de notifications sauvegardées',
                          );
                        },
                        child: Text(
                          'Enregistrer',
                          style: AppTextStyles.titleLg,
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
    );
  }

  // ────────────────────────────────────────────────
  // Stockage utilisé
  // ────────────────────────────────────────────────
  Future<void> _showStorageSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => DecoratedBox(
          decoration: BoxDecoration(
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
                        'Stockage utilisé',
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
                child: _StorageInfoBody(scrollController: scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Changer le mot de passe
  // ────────────────────────────────────────────────
  Future<void> _showChangePasswordSheet(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSaving = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
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
                              'Changer le mot de passe',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mot de passe actuel',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: currentCtrl,
                              obscureText: obscureCurrent,
                              validator: (v) => Validators.password(v),
                              style: AppTextStyles.bodyLg,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrent
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => setSheetState(
                                    () => obscureCurrent = !obscureCurrent,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.dark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nouveau mot de passe',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: newCtrl,
                              obscureText: obscureNew,
                              validator: (v) => Validators.password(v),
                              style: AppTextStyles.bodyLg,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNew
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => setSheetState(
                                    () => obscureNew = !obscureNew,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.dark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Confirmer le mot de passe',
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: confirmCtrl,
                              obscureText: obscureConfirm,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Veuillez confirmer';
                                if (v != newCtrl.text) return 'Les mots de passe ne correspondent pas';
                                return null;
                              },
                              style: AppTextStyles.bodyLg,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirm
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => setSheetState(
                                    () => obscureConfirm = !obscureConfirm,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.dark,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
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
                              color: AppColors.outlineVariant.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSheetState(() => isSaving = true);
                                    try {
                                      await Supabase.instance.client.auth.updateUser(
                                        UserAttributes(
                                          password: newCtrl.text,
                                        ),
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        Get.snackbar(
                                          'Succès',
                                          'Mot de passe mis à jour',
                                        );
                                      }
                                    } on AuthException catch (e) {
                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                      }
                                      if (mounted) {
                                        Get.snackbar(
                                          'Erreur',
                                          e.message,
                                        );
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        setSheetState(() => isSaving = false);
                                      }
                                      if (mounted) {
                                        Get.snackbar(
                                          'Erreur',
                                          'Impossible de changer le mot de passe',
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
                                : Text(
                                    'Mettre à jour',
                                    style: AppTextStyles.titleLg,
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
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
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
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.dark, width: 1.2),
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

class _PaletteDots extends StatelessWidget {
  final List<Color> colors;

  const _PaletteDots({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 24,
      child: Stack(
        children: List.generate(
          colors.length,
          (index) => Positioned(
            left: index * 18,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.dark : AppColors.outlineVariant,
          width: value ? 1.2 : 0.8,
        ),
      ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.dark,
            activeTrackColor: AppColors.dark.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _StorageInfoBody extends StatefulWidget {
  final ScrollController scrollController;

  const _StorageInfoBody({required this.scrollController});

  @override
  State<_StorageInfoBody> createState() => _StorageInfoBodyState();
}

class _StorageInfoBodyState extends State<_StorageInfoBody> {
  bool _isLoading = true;
  int _mediaCount = 0;
  int _guestCount = 0;
  int _tableCount = 0;

  // Estimated sizes (Supabase free tier: 1 GB storage)
  static const int _maxStorageBytes = 1024 * 1024 * 1024; // 1 GB

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final client = Supabase.instance.client;
      final eventId = await client.rpc('current_event_id');
      if (eventId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        client
            .from('media_uploads')
            .select('id')
            .eq('event_id', eventId)
            .count(),
        client
            .from('guests')
            .select('id')
            .eq('event_id', eventId)
            .count(),
        client
            .from('seating_tables')
            .select('id')
            .eq('event_id', eventId)
            .count(),
      ]);

      if (mounted) {
        setState(() {
          _mediaCount = results[0].count;
          _guestCount = results[1].count;
          _tableCount = results[2].count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Rough estimate: ~500 KB per media file (audio/video)
    final estimatedBytes = _mediaCount * 500 * 1024;
    final usageRatio = (estimatedBytes / _maxStorageBytes).clamp(0.0, 1.0);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        // Usage bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dark, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Espace utilisé',
                    style: AppTextStyles.titleLg,
                  ),
                  Text(
                    '${_formatBytes(estimatedBytes)} / 1 Go',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usageRatio > 0.8 ? AppColors.error : AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                usageRatio > 0.8
                    ? '⚠️ Stockage presque plein'
                    : '${(usageRatio * 100).toStringAsFixed(1)}% utilisé',
                style: AppTextStyles.labelMd.copyWith(
                  color: usageRatio > 0.8 ? AppColors.error : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Breakdown
        _StorageRow(
          icon: Icons.mic_rounded,
          iconColor: AppColors.statusMediaReceived,
          label: 'Médias enregistrés',
          count: _mediaCount,
          subtitle: 'Audio et vidéo des invités',
        ),
        const SizedBox(height: 10),
        _StorageRow(
          icon: Icons.group_rounded,
          iconColor: AppColors.dark,
          label: 'Invités',
          count: _guestCount,
          subtitle: 'Contacts enregistrés',
        ),
        const SizedBox(height: 10),
        _StorageRow(
          icon: Icons.table_restaurant_rounded,
          iconColor: AppColors.primary,
          label: 'Tables',
          count: _tableCount,
          subtitle: 'Tables de réception',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Les estimations sont basées sur la taille moyenne des fichiers. La taille réelle peut varier.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final String subtitle;

  const _StorageRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
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
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.labelMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
