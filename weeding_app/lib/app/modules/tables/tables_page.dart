import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import 'tables_controller.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TablesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tables', style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Rechercher une table...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Table List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final tables = controller.filteredTables;

              if (tables.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 64,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune table',
                        style: AppTextStyles.headlineMdPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour créer une table',
                        style: AppTextStyles.bodyMdOnVariant,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        onTap: () => Get.toNamed(
                          AppRoutes.tableDetail,
                          arguments: table,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.table_restaurant,
                            color: AppColors.secondaryContainer,
                          ),
                        ),
                        title: Text(table.label, style: AppTextStyles.titleLg),
                        subtitle: Text(
                          'Capacité : ${table.capacity}',
                          style: AppTextStyles.bodyMdOnVariant,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.outlineVariant,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTableDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNav(2),
    );
  }

  void _showCreateTableDialog(
    BuildContext context,
    TablesController controller,
  ) {
    final labelController = TextEditingController();
    final capacityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle table', style: AppTextStyles.headlineMdPrimary),
              const SizedBox(height: 20),
              Text('Nom de la table', style: AppTextStyles.labelMd),
              const SizedBox(height: 4),
              TextFormField(
                controller: labelController,
                validator: (v) => Validators.required(v, 'Le nom'),
                decoration: const InputDecoration(hintText: 'Table 1'),
              ),
              const SizedBox(height: 12),
              Text(
                'Capacité (nombre de chaises)',
                style: AppTextStyles.labelMd,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
                decoration: const InputDecoration(hintText: '10'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      controller.createTable(
                        label: labelController.text.trim(),
                        capacity: int.parse(capacityController.text),
                      );
                    }
                  },
                  child: const Text('Créer la table'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 2) return; // déjà sur tables
        final routes = [
          AppRoutes.home,
          AppRoutes.guests,
          AppRoutes.tables,
          AppRoutes.invitations,
          AppRoutes.settings,
        ];
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
