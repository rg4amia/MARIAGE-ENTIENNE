import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/invitation_sender.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/shared_components.dart';
import '../../core/widgets/wedding_header.dart';
import '../../routes/app_routes.dart';
import 'guests_controller.dart';

class GuestsPage extends StatelessWidget {
  const GuestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GuestsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          WeddingHeader(
            title: 'Invités',
            showBack: false,
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.filter_list_rounded,
                color: AppColors.dark,
                size: 22,
              ),
            ),
          ),
          // ── Search + Filters ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBar(controller: controller),
                const SizedBox(height: 12),
                Obx(() => _buildFilterChips(controller)),
                // Envoi en masse aux invités qui n'ont pas encore répondu.
                Obx(() {
                  final awaiting = controller.guestsAwaitingRsvp;
                  if (awaiting.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showBulkInvitationSheet(
                          context: context,
                          guests: awaiting,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          'Envoyer en masse (${awaiting.length})',
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dark,
                          side: BorderSide(
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Guest List ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.dark),
                );
              }

              final guests = controller.filteredGuests;

              if (guests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.group_rounded,
                          size: 40,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Aucun invité', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour ajouter\nvotre premier invité',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMdOnVariant,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: guests.length,
                itemBuilder: (context, index) {
                  final guest = guests[index];
                  return FadeInSlide(
                    delay: Duration(milliseconds: index * 50),
                    duration: const Duration(milliseconds: 400),
                    child: _GuestCard(
                      guest: guest,
                      onTap: () =>
                          Get.toNamed(AppRoutes.guestDetail, arguments: guest),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: () => _showAddGuestDialog(context, controller),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 28),
        ),
      ),
    );
  }

  void _showAddGuestDialog(BuildContext context, GuestsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddGuestSheet(controller: controller),
    );
  }
}

// ── Search Bar ──
class _SearchBar extends StatelessWidget {
  final GuestsController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        onChanged: controller.onSearchChanged,
        style: AppTextStyles.bodyLg,
        decoration: InputDecoration(
          hintText: 'Rechercher un invité...',
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ── Filter Chips ──
Widget _buildFilterChips(GuestsController controller) {
  final filters = [
    ('Tous', 'all', controller.guests.length),
    ('À confirmer', 'pending', controller.pendingCount),
    ('Confirmés', 'confirmed', controller.confirmedCount),
    ('Absents', 'declined', controller.declinedCount),
    ('Annulés', 'cancelled', controller.cancelledCount),
  ];

  return SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final (label, key, count) = filters[i];
        final isSelected = controller.filterStatus.value == key;
        return TapScale(
          onTap: () => controller.onFilterChanged(key),
          pressedScale: 0.93,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondary : AppColors.dark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.dark, width: 1.1),
            ),
            child: Text(
              '$label ($count)',
              style: AppTextStyles.labelMd.copyWith(
                color: isSelected ? AppColors.dark : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ── Guest Card ──
class _GuestCard extends StatelessWidget {
  final dynamic guest;
  final VoidCallback onTap;

  const _GuestCard({required this.guest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.dark, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              UserAvatar(
                initials: guest.initials,
                radius: 22,
                backgroundColor: _avatarColor(guest.status),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.fullName,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guest.phone ?? guest.email ?? '',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (guest.status == 'cancelled')
                StatusBadge(label: 'Annulé', color: AppColors.error)
              else
                StatusBadge(
                  label: _rsvpLabel(guest.rsvpStatus),
                  color: _rsvpColor(guest.rsvpStatus),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColor(String status) {
    switch (status) {
      case 'cancelled':
        return AppColors.error;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      case 'media_uploaded':
        return AppColors.statusMediaReceived;
      default:
        return AppColors.dark;
    }
  }

  Color _rsvpColor(String rsvpStatus) {
    switch (rsvpStatus) {
      case 'confirmed':
        return AppColors.statusMediaReceived;
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.statusPending;
    }
  }

  String _rsvpLabel(String rsvpStatus) {
    switch (rsvpStatus) {
      case 'confirmed':
        return 'Présent(e)';
      case 'declined':
        return 'Absent(e)';
      default:
        return 'En attente';
    }
  }
}

// ── Add Guest Bottom Sheet ──
class _AddGuestSheet extends StatefulWidget {
  final GuestsController controller;
  const _AddGuestSheet({required this.controller});

  @override
  State<_AddGuestSheet> createState() => _AddGuestSheetState();
}

class _AddGuestSheetState extends State<_AddGuestSheet> {
  // Les contrôleurs sont créés dans initState pour éviter qu'un rebuild
  // (déclenché par le changement de viewInsets quand le clavier s'ouvre)
  // ne les recrée et ne ferme le clavier.
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Nouvel invité', style: AppTextStyles.headlineMd),
              const SizedBox(height: 20),

              _buildField(
                'Nom complet *',
                TextFormField(
                  controller: _nameController,
                  validator: (v) => Validators.required(v, 'Le nom'),
                  style: AppTextStyles.bodyLg,
                  decoration: _inputDecoration(
                    'Jean Dupont',
                    Icons.person_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildField(
                'Téléphone',
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  style: AppTextStyles.bodyLg,
                  decoration: _inputDecoration(
                    '+225 07 00 00 00 00',
                    Icons.phone_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _buildField(
                'Email (optionnel)',
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.emailOptional,
                  style: AppTextStyles.bodyLg,
                  decoration: _inputDecoration(
                    'jean@mail.com',
                    Icons.mail_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameController.text.trim();
                      final phone = _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim();
                      final email = _emailController.text.trim().isEmpty
                          ? null
                          : _emailController.text.trim();
                      Navigator.pop(context);
                      final guest = await widget.controller.createGuest(
                        fullName: name,
                        phone: phone,
                        email: email,
                      );
                      // Propose l'envoi dès qu'un canal de contact existe
                      // (téléphone ou e-mail).
                      if (guest != null &&
                          context.mounted &&
                          ((phone?.isNotEmpty ?? false) ||
                              (email?.isNotEmpty ?? false))) {
                        showInvitationSendSheet(context: context, guest: guest);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Ajouter l\'invité',
                    style: AppTextStyles.titleLg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
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
        borderSide: BorderSide(color: AppColors.dark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
