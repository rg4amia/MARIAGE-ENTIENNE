import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/wedding_header.dart';
import '../../routes/app_routes.dart';
import 'tables_controller.dart';

class TablesPage extends StatelessWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TablesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Gradient Header ──
          WeddingHeader(
            title: 'Tables',
            showBack: false,
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.dark.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: AppColors.dark,
                size: 22,
              ),
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SearchBar(controller: controller),
          ),
          const SizedBox(height: 16),
          // ── Table List ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.dark));
              }

              final tables = controller.filteredTables;

              if (tables.isEmpty) {
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
                          Icons.table_restaurant_rounded,
                          size: 40,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Aucune table', style: AppTextStyles.headlineMd),
                      const SizedBox(height: 8),
                      Text(
                        'Créez votre première table\npour commencer à organiser',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMdOnVariant,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return FadeInSlide(
                    delay: Duration(milliseconds: index * 60),
                    duration: const Duration(milliseconds: 400),
                    child: _TableCard(
                      table: table,
                      onTap: () => Get.toNamed(
                        AppRoutes.tableDetail,
                        arguments: table,
                      ),
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
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'tables_fab',
          onPressed: () => _showCreateTableDialog(context, controller),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showCreateTableDialog(BuildContext context, TablesController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateTableSheet(controller: controller),
    );
  }
}

// ── Search Bar ──
class _SearchBar extends StatelessWidget {
  final TablesController controller;
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
          hintText: 'Rechercher une table...',
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Table Card with Visual Progress ──
class _TableCard extends StatelessWidget {
  final dynamic table;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Table icon
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
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table.label,
                          style: AppTextStyles.titleLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${table.capacity} chaises',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.outlineVariant,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Capacity indicator
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: table.occupancy.clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          table.occupancy >= 1.0
                              ? AppColors.primary
                              : AppColors.dark,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${table.assignedSeats} / ${table.capacity}',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Table Bottom Sheet ──
class _CreateTableSheet extends StatelessWidget {
  final TablesController controller;
  const _CreateTableSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final labelController = TextEditingController();
    final capacityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

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
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text('Nouvelle table', style: AppTextStyles.headlineMd),
              const SizedBox(height: 20),

              _buildField('Nom de la table', TextFormField(
                controller: labelController,
                validator: (v) => Validators.required(v, 'Le nom'),
                style: AppTextStyles.bodyLg,
                decoration: _inputDecoration('Table 1', Icons.table_restaurant_outlined),
              )),
              const SizedBox(height: 14),

              _buildField('Nombre de chaises', TextFormField(
                controller: capacityController,
                keyboardType: TextInputType.number,
                validator: Validators.positiveNumber,
                style: AppTextStyles.bodyLg,
                decoration: _inputDecoration('10', Icons.event_seat_outlined),
              )),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      await controller.createTable(
                        label: labelController.text.trim(),
                        capacity: int.parse(capacityController.text),
                      );
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
                  child: const Text(
                    'Créer la table',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
        borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
