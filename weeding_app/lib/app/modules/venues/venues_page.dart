import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/models/event_venue.dart';
import 'venues_controller.dart';

class VenuesPage extends StatelessWidget {
  const VenuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VenuesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'Lieux du mariage',
            trailing: IconButton(
              tooltip: 'Actualiser',
              onPressed: controller.loadVenues,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.venues.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.venues.isEmpty) {
                return _EmptyVenues(
                  onAdd: () => _showVenueSheet(context, controller),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadVenues,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                  itemCount: controller.venues.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final venue = controller.venues[index];
                    return _VenueCard(
                      venue: venue,
                      onMap: () => controller.openMap(venue),
                      onEdit: () =>
                          _showVenueSheet(context, controller, venue: venue),
                      onDelete: () =>
                          _confirmDelete(context, controller, venue),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVenueSheet(context, controller),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Ajouter un lieu'),
      ),
    );
  }

  Future<void> _showVenueSheet(
    BuildContext context,
    VenuesController controller, {
    EventVenue? venue,
  }) async {
    final nameController = TextEditingController(text: venue?.name ?? '');
    final addressController = TextEditingController(
      text: venue?.addressLine ?? '',
    );
    final cityController = TextEditingController(text: venue?.city ?? '');
    final latitudeController = TextEditingController(
      text: venue?.latitude?.toString() ?? '',
    );
    final longitudeController = TextEditingController(
      text: venue?.longitude?.toString() ?? '',
    );
    final mapsUrlController = TextEditingController(text: venue?.mapsUrl ?? '');
    final instructionsController = TextEditingController(
      text: venue?.instructions ?? '',
    );
    var venueType = venue?.venueType ?? 'reception';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.65,
            maxChildSize: 0.96,
            expand: false,
            builder: (sheetContext, scrollController) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            venue == null
                                ? 'Ajouter un lieu'
                                : 'Modifier le lieu',
                            style: AppTextStyles.headlineMd,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: venueType,
                            decoration: const InputDecoration(
                              labelText: 'Type de lieu',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'town_hall',
                                child: Text('Mairie'),
                              ),
                              DropdownMenuItem(
                                value: 'church',
                                child: Text('Église / lieu de culte'),
                              ),
                              DropdownMenuItem(
                                value: 'reception',
                                child: Text('Salle de réception'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Autre'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setSheetState(() => venueType = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          _VenueField(
                            controller: nameController,
                            label: 'Nom du lieu',
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 14),
                          _VenueField(
                            controller: addressController,
                            label: 'Adresse',
                            icon: Icons.place_outlined,
                          ),
                          const SizedBox(height: 14),
                          _VenueField(
                            controller: cityController,
                            label: 'Ville',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _VenueField(
                            controller: mapsUrlController,
                            label: 'Lien Google Maps / Apple Plans',
                            icon: Icons.map_outlined,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _VenueField(
                                  controller: latitudeController,
                                  label: 'Latitude',
                                  icon: Icons.my_location_rounded,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _VenueField(
                                  controller: longitudeController,
                                  label: 'Longitude',
                                  icon: Icons.explore_outlined,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _VenueField(
                            controller: instructionsController,
                            label: 'Instructions pour les invités',
                            icon: Icons.info_outline_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : () async {
                                    final saved = await controller.saveVenue(
                                      venue: venue,
                                      venueType: venueType,
                                      name: nameController.text,
                                      addressLine: addressController.text,
                                      city: cityController.text,
                                      latitude: latitudeController.text,
                                      longitude: longitudeController.text,
                                      mapsUrl: mapsUrlController.text,
                                      instructions: instructionsController.text,
                                    );
                                    if (saved && sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                            child: controller.isSaving.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Enregistrer le lieu'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    addressController.dispose();
    cityController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    mapsUrlController.dispose();
    instructionsController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VenuesController controller,
    EventVenue venue,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce lieu ?'),
        content: Text(
          '${venue.name} sera retiré du mariage. Une salle utilisée par le '
          'plan de table ne peut pas être supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteVenue(venue);
  }
}

class _VenueCard extends StatelessWidget {
  final EventVenue venue;
  final VoidCallback onMap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VenueCard({
    required this.venue,
    required this.onMap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final details = venue.addressLabel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _venueColor(venue.venueType).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _venueIcon(venue.venueType),
                  color: _venueColor(venue.venueType),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _venueLabel(venue.venueType),
                      style: AppTextStyles.labelMd,
                    ),
                    const SizedBox(height: 3),
                    Text(venue.name, style: AppTextStyles.titleLg),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        details,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          if (venue.instructions?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Text(
              venue.instructions!,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onMap,
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Ouvrir l’itinéraire'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _VenueField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _EmptyVenues extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyVenues({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 68, color: AppColors.outline),
            const SizedBox(height: 18),
            Text('Aucun lieu configuré', style: AppTextStyles.headlineMd),
            const SizedBox(height: 8),
            Text(
              'Ajoutez la mairie, l’église et la salle de réception.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMdOnVariant,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Ajouter un lieu'),
            ),
          ],
        ),
      ),
    );
  }
}

String _venueLabel(String type) {
  return switch (type) {
    'town_hall' => 'MAIRIE',
    'church' => 'ÉGLISE / CULTE',
    'reception' => 'RÉCEPTION',
    _ => 'AUTRE LIEU',
  };
}

IconData _venueIcon(String type) {
  return switch (type) {
    'town_hall' => Icons.account_balance_rounded,
    'church' => Icons.church_rounded,
    'reception' => Icons.celebration_rounded,
    _ => Icons.place_rounded,
  };
}

Color _venueColor(String type) {
  return switch (type) {
    'town_hall' => AppColors.primary,
    'church' => AppColors.tertiary,
    'reception' => AppColors.secondary,
    _ => AppColors.dark,
  };
}
