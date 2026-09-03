// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/guest.dart';
import '../../data/models/guest_link.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/invitation_sender.dart';
import '../../core/utils/quota_error.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/wedding_header.dart';
import '../subscription/subscription_controller.dart';
import 'guests_controller.dart';

class GuestDetailPage extends StatefulWidget {
  const GuestDetailPage({super.key});

  @override
  State<GuestDetailPage> createState() => _GuestDetailPageState();
}

class _GuestDetailPageState extends State<GuestDetailPage> {
  Guest? _guest;
  GuestLink? _guestLink;
  bool _isLoadingLink = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Guest) {
      _guest = args;
    }
    _loadOrCreateLink();
  }

  Future<void> _loadOrCreateLink() async {
    final guestId = _guest?.id;
    if (guestId == null) {
      if (mounted) {
        setState(() {
          _isLoadingLink = false;
        });
      }
      return;
    }
    final linkRepo = GuestLinkRepository();

    GuestLink? link;
    try {
      link = await linkRepo.getLinkByGuestId(guestId);
      link ??= await linkRepo.createGuestLink(guestId);
    } catch (error) {
      debugPrint('Impossible de charger le lien invité: $error');
    }

    if (mounted) {
      setState(() {
        _guestLink = link;
        _isLoadingLink = false;
      });
    }
  }

  String _getInviteUrl() {
    if (_guestLink == null) return '';
    final supabaseUrl = Supabase.instance.client.rest.url;
    final baseUrl = supabaseUrl.replaceAll(RegExp(r'/rest/v1.*'), '');
    return _guestLink!.getInviteUrl(baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final guest = _guest;
    if (guest == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Aucun invité fourni en paramètre.')),
      );
    }

    final controller = Get.find<GuestsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'Détails invité',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modifier les coordonnées de l'invité.
                GestureDetector(
                  onTap: () => _showEditGuestSheet(context, controller, guest),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: AppColors.dark,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, controller, guest),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.dark,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            child: Text(
                              guest.initials,
                              style: AppTextStyles.displayMdPrimary.copyWith(
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(guest.fullName, style: AppTextStyles.titleLg),
                          const SizedBox(height: 4),

                          if (guest.phone != null)
                            Text(
                              guest.phone!,
                              style: AppTextStyles.bodyMdOnVariant,
                            ),

                          if (guest.email != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mail,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  guest.email!,
                                  style: AppTextStyles.bodyMdOnVariant,
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.dark),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Statut', style: AppTextStyles.bodyMd),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      guest.status,
                                    ).withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    guest.statusLabel,
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: _statusColor(guest.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Réponse à l'invitation : la place n'est attribuée
                          // qu'après confirmation de présence.
                          if (guest.status != 'cancelled') ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _rsvpColor(
                                  guest.rsvpStatus,
                                ).withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _rsvpColor(guest.rsvpStatus),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    guest.rsvpStatus == 'confirmed'
                                        ? Icons.check_circle_rounded
                                        : guest.rsvpStatus == 'declined'
                                        ? Icons.cancel_outlined
                                        : Icons.schedule_rounded,
                                    size: 20,
                                    color: _rsvpColor(guest.rsvpStatus),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          guest.rsvpStatusLabel,
                                          style: AppTextStyles.bodyMd.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.dark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _rsvpMessage(guest),
                                          style: AppTextStyles.labelMd.copyWith(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          FutureBuilder(
                            future: controller.getGuestSeat(guest.id),
                            builder: (context, snapshot) {
                              final seat = snapshot.data;
                              return Column(
                                children: [
                                  _InfoRow(
                                    label: 'Table:',
                                    value: seat?.tableLabel ?? 'Non assignée',
                                  ),
                                  const SizedBox(height: 8),
                                  _InfoRow(
                                    label: 'Chaise:',
                                    value: seat == null
                                        ? 'Non assignée'
                                        : '${seat.chairNumber}',
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assign + Share Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: guest.status == 'cancelled'
                              ? null
                              : () => _showAssignDialog(
                                  context,
                                  controller,
                                  guest,
                                ),
                          icon: const Icon(Icons.chair_rounded, size: 20),
                          label: const Text(
                            'Assigner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                            textStyle: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (guest.qrToken.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: guest.status == 'cancelled'
                                ? null
                                : () => _shareViaWhatsApp(guest),
                            icon: const Icon(Icons.share_rounded, size: 20),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              textStyle: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            label: const Text(
                              'Partager',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Envoi de l'invitation : le canal dépend des coordonnées
                  // (WhatsApp, e-mail, partage système ou copie du lien).
                  if (guest.status != 'cancelled')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => showInvitationSendSheet(
                          context: context,
                          guest: guest,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 20),
                        label: Text(
                          'Envoyer l\'invitation à ${guest.fullName.split(' ').first}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          textStyle: AppTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Cancel or reactivate without deleting the guest history.
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _confirmCancellation(context, controller, guest),
                      icon: Icon(
                        guest.status == 'cancelled'
                            ? Icons.undo_rounded
                            : Icons.person_off_outlined,
                        size: 20,
                      ),
                      label: Text(
                        guest.status == 'cancelled'
                            ? 'Réactiver l\'invité'
                            : 'Annuler l\'invité',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: guest.status == 'cancelled'
                            ? AppColors.dark
                            : AppColors.error,
                        side: BorderSide(
                          color: guest.status == 'cancelled'
                              ? AppColors.dark.withValues(alpha: 0.35)
                              : AppColors.error.withValues(alpha: 0.6),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code & Invite Link
                  if (guest.qrToken.isNotEmpty && guest.status != 'cancelled')
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Lien d\'invitation',
                              style: AppTextStyles.titleLg,
                            ),
                            const SizedBox(height: 12),

                            if (_isLoadingLink)
                              const CircularProgressIndicator()
                            else if (_guestLink != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.dark),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 16,
                                      color: AppColors.dark,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _getInviteUrl(),
                                        style: AppTextStyles.labelMd.copyWith(
                                          color: AppColors.dark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: _getInviteUrl()),
                                        );
                                        Get.snackbar(
                                          'Copié !',
                                          'Lien copié dans le presse-papier',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_red_eye,
                                    size: 14,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_guestLink!.scanCount} scan(s)',
                                    style: AppTextStyles.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 16),

                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.dark,
                                  width: 1.4,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: _guestLink == null
                                    ? const Icon(Icons.lock_outline, size: 60)
                                    : QrImageView(data: _getInviteUrl()),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Code: ${_guestLink?.shortCode ?? "..."}',
                              style: AppTextStyles.labelMd,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(
    BuildContext context,
    GuestsController controller,
    Guest guest,
  ) async {
    final tables = await controller.getAllTables();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AssignSheet(
        tables: tables,
        controller: controller,
        guest: guest,
        onAssigned: _loadOrCreateLink,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    GuestsController controller,
    Guest guest,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'invité ?'),
        content: Text('Voulez-vous vraiment supprimer "${guest.fullName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteGuest(guest.id);
            },
            child: Text(
              'Supprimer',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancellation(
    BuildContext context,
    GuestsController controller,
    Guest guest,
  ) {
    final isCancelled = guest.status == 'cancelled';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCancelled ? 'Réactiver l\'invité ?' : 'Annuler l\'invité ?',
        ),
        content: Text(
          isCancelled
              ? 'L\'invité pourra de nouveau recevoir son invitation. Une nouvelle place devra être assignée.'
              : 'L\'invité sera conservé dans l\'historique, sa place libérée et son lien désactivé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.setGuestCancelled(guest.id, cancelled: !isCancelled);
            },
            child: Text(
              isCancelled ? 'Réactiver' : 'Annuler',
              style: AppTextStyles.bodyMd.copyWith(
                color: isCancelled ? AppColors.dark : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'cancelled':
        return AppColors.error;
      case 'media_uploaded':
        return AppColors.statusMediaReceived;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      default:
        return AppColors.statusPending;
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

  String _rsvpMessage(Guest guest) {
    switch (guest.rsvpStatus) {
      case 'confirmed':
        return 'Présence confirmée — vous pouvez lui attribuer une table et une place.';
      case 'declined':
        return 'A décliné l\'invitation : aucune place à prévoir.';
      default:
        return 'En attente de réponse à l\'invitation.';
    }
  }

  Future<void> _shareViaWhatsApp(Guest guest) async {
    final url = _getInviteUrl();
    if (url.isEmpty) {
      Get.snackbar('Erreur', 'Aucun lien d\'invitation disponible');
      return;
    }

    // L'invitation n'existe en base qu'une fois la place attribuée : sans
    // elle, l'envoi ne peut être ni décompté ni retrouvé à l'entrée.
    final invitation = await InvitationRepository().getInvitationByGuestId(
      guest.id,
    );
    if (invitation == null) {
      Get.snackbar(
        'Place à attribuer',
        'Placez ${guest.fullName.split(' ').first} à une table avant '
            'd\'envoyer son invitation.',
      );
      return;
    }

    final sent = await runWithQuotaGuard(() async {
      await InvitationRepository().recordDelivery(
        invitationId: invitation.id,
        destination: guest.phone,
      );
    });
    if (!sent) return;

    final name = guest.fullName.split(' ').first;
    final message =
        'Bonjour $name ! 🎉\n\n'
        'Tu es invité(e) au mariage ! 🥂\n'
        'Clique sur le lien ci-dessous pour accéder à ton invitation :\n\n'
        '$url';
    await Share.share(message);
    await _refreshSubscription();
  }

  Future<void> _refreshSubscription() async {
    if (Get.isRegistered<SubscriptionController>()) {
      await Get.find<SubscriptionController>().load();
    }
  }

  Future<void> _showEditGuestSheet(
    BuildContext context,
    GuestsController controller,
    Guest guest,
  ) async {
    final updated = await showModalBottomSheet<Guest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditGuestSheet(guest: guest, controller: controller),
    );
    if (updated != null && mounted) {
      setState(() => _guest = updated);
      Get.snackbar('Succès', 'Invité modifié');
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isUnassigned = value == 'Non assignée';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMdOnVariant),
        Text(
          value,
          style: AppTextStyles.bodyMd.copyWith(
            color: isUnassigned ? AppColors.statusPending : null,
            fontWeight: isUnassigned ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ── Modifier un invité (nom, téléphone, e-mail) ──
class _EditGuestSheet extends StatefulWidget {
  final Guest guest;
  final GuestsController controller;

  const _EditGuestSheet({required this.guest, required this.controller});

  @override
  State<_EditGuestSheet> createState() => _EditGuestSheetState();
}

class _EditGuestSheetState extends State<_EditGuestSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.guest.fullName);
    _phoneController = TextEditingController(text: widget.guest.phone ?? '');
    _emailController = TextEditingController(text: widget.guest.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final phoneText = _phoneController.text.trim();
    final emailText = _emailController.text.trim();
    final updated = await widget.controller.updateGuest(
      id: widget.guest.id,
      fullName: _nameController.text.trim(),
      phone: phoneText.isEmpty ? null : phoneText,
      email: emailText.isEmpty ? null : emailText,
      clearPhone: (widget.guest.phone ?? '').isNotEmpty && phoneText.isEmpty,
      clearEmail: (widget.guest.email ?? '').isNotEmpty && emailText.isEmpty,
    );

    if (!mounted) return;
    if (updated != null) {
      Navigator.pop(context, updated);
    } else {
      setState(() => _isSaving = false);
    }
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
              Text('Modifier l\'invité', style: AppTextStyles.headlineMd),
              const SizedBox(height: 4),
              Text(
                'Le numéro de téléphone sert à l\'invitation WhatsApp ; '
                'l\'e-mail est facultatif.',
                style: AppTextStyles.bodyMdOnVariant,
              ),
              const SizedBox(height: 20),

              _field(
                'Nom complet *',
                TextFormField(
                  controller: _nameController,
                  validator: (v) => Validators.required(v, 'Le nom'),
                  style: AppTextStyles.bodyLg,
                  decoration: _decoration(
                    'Jean Dupont',
                    Icons.person_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _field(
                'Téléphone',
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  style: AppTextStyles.bodyLg,
                  decoration: _decoration(
                    '+225 07 00 00 00 00',
                    Icons.phone_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _field(
                'Email (optionnel)',
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.emailOptional,
                  style: AppTextStyles.bodyLg,
                  decoration: _decoration(
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
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Enregistrer', style: AppTextStyles.titleLg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, Widget child) {
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

  InputDecoration _decoration(String hint, IconData icon) {
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

class _AssignSheet extends StatefulWidget {
  final List<WeddingTable> tables;
  final GuestsController controller;
  final Guest guest;
  final Future<void> Function() onAssigned;

  const _AssignSheet({
    required this.tables,
    required this.controller,
    required this.guest,
    required this.onAssigned,
  });

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  WeddingTable? selectedTable;
  Chair? selectedChair;
  List<Chair> availableChairs = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assigner une place', style: AppTextStyles.headlineMd),
          const SizedBox(height: 20),

          DropdownButtonFormField<WeddingTable>(
            value: selectedTable,
            decoration: const InputDecoration(labelText: 'Table'),
            items: widget.tables.map((t) {
              return DropdownMenuItem(value: t, child: Text(t.label));
            }).toList(),
            onChanged: (table) async {
              setState(() {
                selectedTable = table;
                selectedChair = null;
                availableChairs = [];
              });
              if (table != null) {
                final chairs = await widget.controller.getAvailableChairs(
                  table.id,
                );
                setState(() => availableChairs = chairs);
              }
            },
          ),
          const SizedBox(height: 12),

          if (selectedTable != null)
            DropdownButtonFormField<Chair>(
              value: selectedChair,
              decoration: const InputDecoration(labelText: 'Chaise'),
              items: availableChairs.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text('Chaise ${c.chairNumber}'),
                );
              }).toList(),
              onChanged: (chair) => setState(() => selectedChair = chair),
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedTable != null && selectedChair != null)
                  ? () async {
                      await widget.controller.assignSeatToGuest(
                        guestId: widget.guest.id,
                        chairId: selectedChair!.id,
                      );
                      await widget.onAssigned();
                    }
                  : null,
              child: const Text('Assigner'),
            ),
          ),
        ],
      ),
    );
  }
}
