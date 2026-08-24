import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/guest.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import 'guests_controller.dart';

class GuestDetailPage extends StatelessWidget {
  const GuestDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GuestsController>();
    final guest = Get.arguments as Guest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Détails invité', style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, controller, guest),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      Text(
                        guest.phone!,
                        style: AppTextStyles.bodyMdOnVariant,
                      ),

                    // Email
                    if (guest.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.mail, size: 16, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(guest.email!, style: AppTextStyles.bodyMdOnVariant),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

                    // Table & Chair
                    _InfoRow(
                      label: 'Table:',
                      value: 'Non assignée', // TODO: join with guest_seats
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Chaise:',
                      value: 'Non assignée',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assign Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAssignDialog(context, controller, guest),
                icon: const Icon(Icons.chair),
                label: const Text('Assigner une place'),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Preview
            if (guest.qrToken.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('QR Code', style: AppTextStyles.titleLg),
                      const SizedBox(height: 8),
                      Text(
                        guest.qrToken,
                        style: AppTextStyles.labelMd,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: AppColors.outlineVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
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

  const _AssignSheet({
    required this.tables,
    required this.controller,
    required this.guest,
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
              return DropdownMenuItem(value: t, child: Text(t.name));
            }).toList(),
            onChanged: (table) async {
              setState(() {
                selectedTable = table;
                selectedChair = null;
                availableChairs = [];
              });
              if (table != null) {
                final chairs = await widget.controller.getAvailableChairs(table.id);
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
                  ? () {
                      widget.controller.assignSeatToGuest(
                        guestId: widget.guest.id,
                        tableId: selectedTable!.id,
                        chairId: selectedChair!.id,
                      );
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
