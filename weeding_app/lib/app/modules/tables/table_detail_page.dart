import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/wedding_header.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import '../../data/models/guest.dart';
import '../../data/repositories/guest_repository.dart';
import 'tables_controller.dart';

class TableDetailPage extends StatelessWidget {
  const TableDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Get.arguments == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Aucune table fournie.')),
      );
    }

    final controller = Get.find<TablesController>();
    final table = Get.arguments as WeddingTable;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ──
          WeddingHeader(
            title: table.label,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TapScale(
                  onTap: () => _showEditDialog(context, controller, table),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppColors.dark, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                TapScale(
                  onTap: () => _confirmDelete(context, controller, table),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.dark, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ──
          Expanded(
            child: FutureBuilder<List<Chair>>(
              future: controller.getChairsForTable(table.id),
              builder: (context, snapshot) {
                final chairs = snapshot.data ?? [];
                final assigned = chairs.where((c) => c.isAssigned).length;
                final occupancy = chairs.isNotEmpty ? assigned / chairs.length : 0.0;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    _buildInfoCard(table, assigned, occupancy),
                    const SizedBox(height: 16),
                    _buildSectionHeader(assigned, chairs.length),
                    const SizedBox(height: 12),
                    if (chairs.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                      _buildEmptyChairs()
                    else
                      _buildChairsGrid(chairs),
                    const SizedBox(height: 24),
                    _buildLegend(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(WeddingTable table, int assigned, double occupancy) {
    return Container(
      width: double.infinity,
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.table_restaurant_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.label,
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.dark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${table.capacity} chaises',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: occupancy >= 1.0
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.dark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$assigned/${table.capacity}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: occupancy >= 1.0
                        ? AppColors.primaryDark
                        : AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 8,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancy >= 1.0
                    ? AppColors.primary
                    : occupancy >= 0.5
                        ? AppColors.dark.withValues(alpha: 0.7)
                        : AppColors.dark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            occupancy >= 1.0
                ? 'Table complète ✓'
                : '${table.capacity - assigned} place${table.capacity - assigned > 1 ? 's' : ''} restante${table.capacity - assigned > 1 ? 's' : ''}',
            style: AppTextStyles.bodyMd.copyWith(
              color: occupancy >= 1.0 ? AppColors.primaryDark : AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int assigned, int total) {
    return Row(
      children: [
        const Icon(Icons.chair_rounded, size: 20, color: AppColors.dark),
        const SizedBox(width: 8),
        Text(
          'Chaises',
          style: AppTextStyles.titleLg.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.dark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$assigned/$total occupée${total != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChairs() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.chair_rounded, size: 40, color: AppColors.outlineVariant),
            SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChairsGrid(List<Chair> chairs) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chairs.map((chair) => _ChairTile(chair: chair)).toList(),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(AppColors.outlineVariant.withValues(alpha: 0.4), 'Libre'),
          const SizedBox(width: 24),
          _legendItem(AppColors.dark.withValues(alpha: 0.12), 'Occupée'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    TablesController controller,
    WeddingTable table,
  ) {
    final labelController = TextEditingController(text: table.label);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modifier la table', style: AppTextStyles.headlineMd),
              const SizedBox(height: 20),
              TextFormField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    controller.updateTable(
                      id: table.id,
                      label: labelController.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    TablesController controller,
    WeddingTable table,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la table ?'),
        content: Text('Voulez-vous vraiment supprimer "${table.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => controller.deleteTable(table.id),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChairTile extends StatelessWidget {
  final Chair chair;

  const _ChairTile({required this.chair});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () {
        if (chair.isAssigned) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => _GuestDetailSheet(chair: chair),
          );
        }
      },
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: chair.isAssigned
              ? AppColors.dark.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: chair.isAssigned
                ? AppColors.dark
                : AppColors.outlineVariant.withValues(alpha: 0.4),
            width: chair.isAssigned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chair_rounded,
              color: chair.isAssigned
                  ? AppColors.dark
                  : AppColors.outlineVariant,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              'N°${chair.chairNumber}',
              style: AppTextStyles.labelMd.copyWith(
                fontWeight: FontWeight.w700,
                color: chair.isAssigned
                    ? AppColors.dark
                    : AppColors.onSurfaceVariant,
              ),
            ),
            if (chair.isAssigned && chair.guestName != null) ...[
              const SizedBox(height: 3),
              Text(
                chair.guestName!.length > 8
                    ? '${chair.guestName!.substring(0, 8)}…'
                    : chair.guestName!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMd.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ] else if (chair.isAssigned) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 10,
                  color: AppColors.dark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestDetailSheet extends StatefulWidget {
  final Chair chair;

  const _GuestDetailSheet({required this.chair});

  @override
  State<_GuestDetailSheet> createState() => _GuestDetailSheetState();
}

class _GuestDetailSheetState extends State<_GuestDetailSheet> {
  final GuestRepository _guestRepository = GuestRepository();
  Guest? _guest;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuest();
  }

  Future<void> _loadGuest() async {
    try {
      if (widget.chair.guestId == null) {
        if (mounted) {
          setState(() {
            _error = 'Aucun invité assigné';
            _isLoading = false;
          });
        }
        return;
      }
      final guest = await _guestRepository.getGuestById(widget.chair.guestId!);
      if (mounted) {
        setState(() {
          _guest = guest;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les détails';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.dark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chair.guestName ?? 'Invité',
                      style: AppTextStyles.headlineMd.copyWith(color: AppColors.dark),
                    ),
                    Text(
                      'Chaise N°${widget.chair.chairNumber}',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error))
          else if (_guest != null) ...[
            _buildDetailRow(Icons.phone_outlined, 'Téléphone', _guest!.phone ?? 'Non renseigné'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.email_outlined, 'Email', _guest!.email ?? 'Non renseigné'),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.info_outline_rounded, 'Statut', _guest!.statusLabel),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelMd.copyWith(color: AppColors.onSurfaceVariant)),
            Text(value, style: AppTextStyles.bodyMd),
          ],
        ),
      ],
    );
  }
}
