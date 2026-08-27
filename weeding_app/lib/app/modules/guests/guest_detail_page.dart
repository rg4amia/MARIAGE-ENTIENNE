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
import 'package:share_plus/share_plus.dart';
import '../../core/widgets/wedding_header.dart';
import 'guests_controller.dart';

class GuestDetailPage extends StatefulWidget {
  const GuestDetailPage({super.key});

  @override
  State<GuestDetailPage> createState() => _GuestDetailPageState();
}

class _GuestDetailPageState extends State<GuestDetailPage> {
  GuestLink? _guestLink;
  bool _isLoadingLink = true;

  @override
  void initState() {
    super.initState();
    _loadOrCreateLink();
  }

  Future<void> _loadOrCreateLink() async {
    if (Get.arguments == null) {
      if (mounted) {
        setState(() {
          _isLoadingLink = false;
        });
      }
      return;
    }
    final guest = Get.arguments as Guest;
    final linkRepo = GuestLinkRepository();

    // Try to get existing link
    var link = await linkRepo.getLinkByGuestId(guest.id);

    // Create new link if none exists
    try {
      link ??= await linkRepo.createGuestLink(guest.id);
    } catch (_) {
      // Le lien ne peut être créé qu'après l'attribution d'une chaise.
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
    // Convert REST URL to base: https://xxx.supabase.co/rest/v1/ → https://xxx.supabase.co
    final baseUrl = supabaseUrl.replaceAll(RegExp(r'/rest/v1.*'), '');
    return _guestLink!.getInviteUrl(baseUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (Get.arguments == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Aucun invité fourni en paramètre.')),
      );
    }

    final controller = Get.find<GuestsController>();
    final guest = Get.arguments as Guest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'Détails invité',
            trailing: GestureDetector(
              onTap: () => _confirmDelete(context, controller, guest),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
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
                        style: AppTextStyles.displayMdPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(guest.fullName, style: AppTextStyles.titleLg),
                    const SizedBox(height: 4),

                    // Phone
                    if (guest.phone != null)
                      Text(guest.phone!, style: AppTextStyles.bodyMdOnVariant),

                    // Email
                    if (guest.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
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

                    // Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
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
                              color: _statusColor(guest.status).withAlpha(51),
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
                    onPressed: () => _showAssignDialog(context, controller, guest),
                    icon: const Icon(Icons.chair),
                    label: const Text('Assigner'),
                  ),
                ),
                const SizedBox(width: 12),
                if (guest.qrToken.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareViaWhatsApp(guest),
                      icon: const Icon(Icons.share_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      label: const Text('WhatsApp'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code & Invite Link
            if (guest.qrToken.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('Lien d\'invitation', style: AppTextStyles.titleLg),

                      // WhatsApp share shortcut
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _shareViaWhatsApp(guest),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF25D366).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share_rounded, size: 14, color: Color(0xFF25D366)),
                              SizedBox(width: 4),
                              Text(
                                'Partager via WhatsApp',
                                style: TextStyle(
                                  color: Color(0xFF25D366),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Short link display
                      if (_isLoadingLink)
                        const CircularProgressIndicator()
                      else if (_guestLink != null) ...[
                        // Short link URL
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.link,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getInviteUrl(),
                                  style: AppTextStyles.labelMd.copyWith(
                                    color: AppColors.primary,
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

                        // Stats
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

                      // QR Code du lien court public
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        title: const Text('Supprimer l\'invité ?'),
        content: Text('Voulez-vous vraiment supprimer "${guest.fullName}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => controller.deleteGuest(guest.id),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'media_uploaded':
        return AppColors.secondary;
      case 'card_unlocked':
        return const Color(0xFF2E7D32);
      default:
        return AppColors.onTertiaryContainer;
    }
  }

  void _shareViaWhatsApp(Guest guest) {
    final url = _getInviteUrl();
    if (url.isEmpty) {
      Get.snackbar('Erreur', 'Aucun lien d\'invitation disponible');
      return;
    }
    final name = guest.fullName.split(' ').first;
    final message = 'Bonjour $name ! 🎉\n\n'
        'Tu es invité(e) au mariage ! 🥂\n'
        'Clique sur le lien ci-dessous pour accéder à ton invitation :\n\n'
        '$url';
    Share.share(message);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMdOnVariant),
        Text(value, style: AppTextStyles.bodyMd),
      ],
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
          Text('Assigner une place', style: AppTextStyles.headlineMdPrimary),
          const SizedBox(height: 20),

          // Table selector
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

          // Chair selector
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
