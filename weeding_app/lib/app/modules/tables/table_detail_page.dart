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
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppColors.dark,
                      size: 20,
                    ),
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

          // ── Scrollable body ──
          Expanded(
            child: _TableChairsSection(controller: controller, table: table),
          ),
        ],
      ),
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
            onPressed: () => controller.deleteTable(table.id),              child: Text(
              'Supprimer',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chairs section (loads chairs, allows assigning/moving/unassigning) ──
class _TableChairsSection extends StatefulWidget {
  final TablesController controller;
  final WeddingTable table;

  const _TableChairsSection({required this.controller, required this.table});

  @override
  State<_TableChairsSection> createState() => _TableChairsSectionState();
}

class _TableChairsSectionState extends State<_TableChairsSection> {
  late Future<List<Chair>> _chairsFuture;

  @override
  void initState() {
    super.initState();
    _loadChairs();
  }

  void _loadChairs() {
    _chairsFuture = widget.controller.getChairsForTable(widget.table.id);
  }

  void _refresh() {
    setState(_loadChairs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Chair>>(
      future: _chairsFuture,
      builder: (context, snapshot) {
        final chairs = snapshot.data ?? [];
        final assigned = chairs.where((c) => c.isAssigned).length;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        // Use the table's capacity as the denominator while still loading
        // so the header doesn't flash "0/0" before chairs arrive.
        final totalForHeader = isLoading ? widget.table.capacity : chairs.length;
        final occupancy = totalForHeader > 0 ? assigned / totalForHeader : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildInfoCard(assigned, occupancy),
            const SizedBox(height: 16),
            _buildSectionHeader(assigned, totalForHeader),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              _buildLoadingChairs()
            else if (snapshot.hasError)
              _buildChairsError(snapshot.error.toString())
            else if (chairs.isEmpty)
              _buildEmptyChairs()
            else
              _buildChairsGrid(chairs),
            const SizedBox(height: 24),
            _buildLegend(),
          ],
        );
      },
    );
  }

  void _handleChairTap(Chair chair) {
    if (chair.isAssigned) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _GuestDetailSheet(
          chair: chair,
          controller: widget.controller,
          currentTable: widget.table,
          onChanged: _refresh,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => _AssignGuestSheet(
          chair: chair,
          controller: widget.controller,
          onAssigned: _refresh,
        ),
      );
    }
  }

  void _confirmDeleteChair(Chair chair) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer la chaise N°${chair.chairNumber} ?'),
        content: const Text(
          'Cette place sera retirée de la table et la capacité sera réduite d\'une unité.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.controller.deleteChair(chair.id);
              _refresh();
            },              child: Text(
              'Supprimer',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(int assigned, double occupancy) {
    final table = widget.table;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.35),
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
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.label,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.dark,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: occupancy >= 1.0
                      ? AppColors.primary
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.dark),
                ),
                child: Text(
                  '$assigned/${table.capacity}',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
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
              color: occupancy >= 1.0
                  ? AppColors.primaryDark
                  : AppColors.onSurfaceVariant,
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
        Icon(Icons.chair_rounded, size: 20, color: AppColors.dark),
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
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingChairs() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(height: 24),
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Chargement des chaises…',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChairs() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.chair_rounded,
              size: 40,
              color: AppColors.outlineVariant,
            ),
            SizedBox(height: 8),
            Text(
              'Aucune chaise pour cette table',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChairsError(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark, width: 1.2),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              'Erreur de chargement des chaises',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _refresh, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _buildChairsGrid(List<Chair> chairs) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chairs
          .map((chair) => _ChairTile(
                chair: chair,
                onTap: () => _handleChairTap(chair),
                onLongPress: chair.isAssigned
                    ? null
                    : () => _confirmDeleteChair(chair),
              ))
          .toList(),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dark, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.white, 'Libre'),
              const SizedBox(width: 24),
              _legendItem(AppColors.dark.withValues(alpha: 0.12), 'Occupée'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Astuce : appui long sur une chaise libre pour la supprimer',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
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
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ChairTile extends StatelessWidget {
  final Chair chair;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ChairTile({
    required this.chair,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: chair.isAssigned ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dark, width: 1.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chair.isAssigned ? Icons.chair_rounded : Icons.add_rounded,
              color: chair.isAssigned
                  ? AppColors.dark
                  : AppColors.onSurfaceVariant,
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
                child: Icon(
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

// ── Assign an unassigned guest to an empty chair ──
class _AssignGuestSheet extends StatefulWidget {
  final Chair chair;
  final TablesController controller;
  final VoidCallback onAssigned;

  const _AssignGuestSheet({
    required this.chair,
    required this.controller,
    required this.onAssigned,
  });

  @override
  State<_AssignGuestSheet> createState() => _AssignGuestSheetState();
}

class _AssignGuestSheetState extends State<_AssignGuestSheet> {
  late Future<List<Guest>> _guestsFuture;
  String _query = '';
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _guestsFuture = widget.controller.getUnassignedGuests();
  }

  Future<void> _assign(Guest guest) async {
    setState(() => _isAssigning = true);
    await widget.controller.assignGuestToChair(
      guestId: guest.id,
      chairId: widget.chair.id,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onAssigned();
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
          Text(
            'Placer un invité — Chaise N°${widget.chair.chairNumber}',
            style: AppTextStyles.headlineMd,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher un invité...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: FutureBuilder<List<Guest>>(
              future: _guestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final guests = (snapshot.data ?? [])
                    .where(
                      (g) => g.fullName.toLowerCase().contains(
                            _query.toLowerCase(),
                          ),
                    )
                    .toList();

                if (guests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucun invité disponible',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: guests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final guest = guests[index];
                    return TapScale(
                      onTap: _isAssigning ? null : () => _assign(guest),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.dark.withValues(
                                alpha: 0.1,
                              ),
                              child: Text(
                                guest.initials,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                guest.fullName,
                                style: AppTextStyles.bodyLg,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.outlineVariant,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestDetailSheet extends StatefulWidget {
  final Chair chair;
  final TablesController controller;
  final WeddingTable currentTable;
  final VoidCallback onChanged;

  const _GuestDetailSheet({
    required this.chair,
    required this.controller,
    required this.currentTable,
    required this.onChanged,
  });

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

  Future<void> _openMoveSheet() async {
    final guestId = widget.chair.guestId;
    if (guestId == null) return;
    Navigator.pop(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MoveGuestSheet(
        guestId: guestId,
        currentChairId: widget.chair.id,
        controller: widget.controller,
        onMoved: widget.onChanged,
      ),
    );
  }

  void _confirmUnassign() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Libérer la place ?'),
        content: Text(
          '${_guest?.fullName ?? 'Cet invité'} ne sera plus assigné à cette chaise.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final guestId = widget.chair.guestId;
              if (guestId == null) return;
              await widget.controller.unassignGuestFromChair(guestId);
              if (mounted) {
                Navigator.pop(context);
                widget.onChanged();
              }
            },
            child: Text(
              'Libérer',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
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
                child: Icon(Icons.person_rounded, color: AppColors.dark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chair.guestName ?? 'Invité',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      'Chaise N°${widget.chair.chairNumber}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
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
            Text(_error!, style: AppTextStyles.bodyMd.copyWith(color: AppColors.error))
          else if (_guest != null) ...[
            _buildDetailRow(
              Icons.phone_outlined,
              'Téléphone',
              _guest!.phone ?? 'Non renseigné',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.email_outlined,
              'Email',
              _guest!.email ?? 'Non renseigné',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.info_outline_rounded,
              'Statut',
              _guest!.statusLabel,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMoveSheet,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  label: const Text('Déplacer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _confirmUnassign,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.event_seat_outlined, size: 20),
                  label: const Text('Libérer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            Text(value, style: AppTextStyles.bodyMd),
          ],
        ),
      ],
    );
  }
}

// ── Move an already-assigned guest to a different table/chair ──
class _MoveGuestSheet extends StatefulWidget {
  final String guestId;
  final String currentChairId;
  final TablesController controller;
  final VoidCallback onMoved;

  const _MoveGuestSheet({
    required this.guestId,
    required this.currentChairId,
    required this.controller,
    required this.onMoved,
  });

  @override
  State<_MoveGuestSheet> createState() => _MoveGuestSheetState();
}

class _MoveGuestSheetState extends State<_MoveGuestSheet> {
  WeddingTable? _selectedTable;
  Chair? _selectedChair;
  List<Chair> _availableChairs = [];
  bool _isMoving = false;

  Future<void> _onTableSelected(WeddingTable? table) async {
    setState(() {
      _selectedTable = table;
      _selectedChair = null;
      _availableChairs = [];
    });
    if (table != null) {
      final chairs = await widget.controller.getChairsForTable(table.id);
      final available = chairs
          .where((c) => !c.isAssigned || c.id == widget.currentChairId)
          .toList();
      setState(() => _availableChairs = available);
    }
  }

  Future<void> _confirmMove() async {
    final chair = _selectedChair;
    if (chair == null) return;
    setState(() => _isMoving = true);
    await widget.controller.assignGuestToChair(
      guestId: widget.guestId,
      chairId: chair.id,
    );
    if (mounted) {
      Navigator.pop(context);
      widget.onMoved();
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
          Text('Déplacer l\'invité', style: AppTextStyles.headlineMd),
          const SizedBox(height: 20),
          Obx(
            () => DropdownButtonFormField<WeddingTable>(
              value: _selectedTable,
              decoration: const InputDecoration(labelText: 'Table'),
              items: widget.controller.tables
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                  )
                  .toList(),
              onChanged: _onTableSelected,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedTable != null)
            DropdownButtonFormField<Chair>(
              value: _selectedChair,
              decoration: const InputDecoration(labelText: 'Chaise'),
              items: _availableChairs
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.id == widget.currentChairId
                            ? 'Chaise ${c.chairNumber} (actuelle)'
                            : 'Chaise ${c.chairNumber}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (chair) => setState(() => _selectedChair = chair),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_selectedChair != null &&
                          _selectedChair!.id != widget.currentChairId &&
                          !_isMoving)
                      ? _confirmMove
                      : null,
              child: const Text('Déplacer'),
            ),
          ),
        ],
      ),
    );
  }
}
