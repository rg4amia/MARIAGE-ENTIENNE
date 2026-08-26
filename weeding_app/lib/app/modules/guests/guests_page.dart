import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_routes.dart';
import 'guests_controller.dart';

class GuestsPage extends StatelessWidget {
  const GuestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GuestsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invités', style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: TextField(
              onChanged: controller.onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un invité...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.onSurfaceVariant,
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tous (${controller.guests.length})',
                    isSelected: controller.filterStatus.value == 'all',
                    onTap: () => controller.onFilterChanged('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'En attente (${controller.pendingCount})',
                    isSelected: controller.filterStatus.value == 'pending',
                    onTap: () => controller.onFilterChanged('pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Confirmés (${controller.confirmedCount})',
                    isSelected: controller.filterStatus.value == 'confirmed',
                    onTap: () => controller.onFilterChanged('confirmed'),
                  ),
                ],
              ),
            ),
          ),

          // Guest List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final guests = controller.filteredGuests;

              if (guests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.group,
                        size: 64,
                        color: AppColors.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun invité',
                        style: AppTextStyles.headlineMdPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur + pour ajouter un invité',
                        style: AppTextStyles.bodyMdOnVariant,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                itemCount: guests.length,
                itemBuilder: (context, index) {
                  final guest = guests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        onTap: () => Get.toNamed(
                          AppRoutes.guestDetail,
                          arguments: guest,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          child: Text(
                            guest.initials,
                            style: AppTextStyles.titleLg.copyWith(fontSize: 14),
                          ),
                        ),
                        title: Text(
                          guest.fullName,
                          style: AppTextStyles.titleLg,
                        ),
                        subtitle: Text(
                          guest.phone ?? guest.email ?? '',
                          style: AppTextStyles.bodyMdOnVariant,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusBadge(status: guest.status),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.outlineVariant,
                            ),
                          ],
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
        onPressed: () => _showAddGuestDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  void _showAddGuestDialog(BuildContext context, GuestsController controller) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
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
              Text('Nouvel invité', style: AppTextStyles.headlineMdPrimary),
              const SizedBox(height: 20),
              Text('Nom complet *', style: AppTextStyles.labelMd),
              const SizedBox(height: 4),
              TextFormField(
                controller: nameController,
                validator: (v) => Validators.required(v, 'Le nom'),
                decoration: const InputDecoration(hintText: 'Jean Dupont'),
              ),
              const SizedBox(height: 12),
              Text('Téléphone', style: AppTextStyles.labelMd),
              const SizedBox(height: 4),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
                decoration: const InputDecoration(
                  hintText: '+225 07 00 00 00 00',
                ),
              ),
              const SizedBox(height: 12),
              Text('Email', style: AppTextStyles.labelMd),
              const SizedBox(height: 4),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                decoration: const InputDecoration(hintText: 'jean@mail.com'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      controller.createGuest(
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                      );
                    }
                  },
                  child: const Text('Ajouter l\'invité'),
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
        if (index == 1) return; // déjà sur guests
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: AppColors.outlineVariant),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'media_uploaded':
        bgColor = AppColors.secondaryContainer.withAlpha(51);
        textColor = AppColors.secondary;
        label = 'Média';
        break;
      case 'card_unlocked':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        label = 'Débloquée';
        break;
      default:
        bgColor = AppColors.tertiaryFixed.withAlpha(128);
        textColor = AppColors.onTertiaryContainer;
        label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: textColor, fontSize: 10),
      ),
    );
  }
}
