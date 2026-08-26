import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/wedding_table.dart';
import '../../data/models/chair.dart';
import 'tables_controller.dart';

class TableDetailPage extends StatelessWidget {
  const TableDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TablesController>();
    final table = Get.arguments as WeddingTable;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(table.label, style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, controller, table),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, controller, table),
          ),
        ],
      ),
      body: Column(
        children: [
          // Table info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(table.label, style: AppTextStyles.headlineMdPrimary),
                    const SizedBox(height: 8),
                    Text(
                      'Capacité : ${table.capacity} chaises',
                      style: AppTextStyles.bodyLg,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Chairs grid
          Expanded(
            child: FutureBuilder<List<Chair>>(
              future: controller.getChairsForTable(table.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chairs = snapshot.data ?? [];

                if (chairs.isEmpty) {
                  return const Center(child: Text('Aucune chaise'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: chairs.length,
                  itemBuilder: (context, index) {
                    final chair = chairs[index];
                    return _ChairTile(chair: chair);
                  },
                );
              },
            ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              Text('Modifier la table', style: AppTextStyles.headlineMdPrimary),
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
    return Container(
      decoration: BoxDecoration(
        color: chair.isAssigned
            ? AppColors.primaryContainer.withAlpha(51)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chair.isAssigned
              ? AppColors.primaryContainer
              : AppColors.outlineVariant,
          width: chair.isAssigned ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chair,
            color: chair.isAssigned
                ? AppColors.primaryContainer
                : AppColors.outlineVariant,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '${chair.chairNumber}',
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w600,
              color: chair.isAssigned
                  ? AppColors.primaryContainer
                  : AppColors.onSurfaceVariant,
            ),
          ),
          if (chair.isAssigned)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Occupée',
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
