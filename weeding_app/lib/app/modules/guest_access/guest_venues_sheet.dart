import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/venue_presentation.dart';
import '../../data/models/event_venue.dart';
import 'guest_access_controller.dart';

/// Feuille en lecture seule listant les lieux du mariage pour que l'invité
/// puisse s'orienter (adresse + itinéraire), sans droits d'édition.
Future<void> showGuestVenuesSheet(
  BuildContext context,
  GuestAccessController controller,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
                          'Lieux du mariage',
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
                  child: Obx(() {
                    if (controller.venues.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Aucun lieu n\'a encore été renseigné.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMdOnVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: controller.venues.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, index) {
                        final venue = controller.venues[index];
                        return _GuestVenueCard(
                          venue: venue,
                          onMap: () => controller.openVenueMap(venue),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _GuestVenueCard extends StatelessWidget {
  final EventVenue venue;
  final VoidCallback onMap;

  const _GuestVenueCard({required this.venue, required this.onMap});

  @override
  Widget build(BuildContext context) {
    final details = venue.addressLabel;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.dark, width: 1.2),
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
                  color: venueColor(venue.venueType),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  venueIcon(venue.venueType),
                  color: venueColor(venue.venueType).computeLuminance() > 0.5
                      ? AppColors.dark
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venueLabel(venue.venueType), style: AppTextStyles.labelMd),
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
