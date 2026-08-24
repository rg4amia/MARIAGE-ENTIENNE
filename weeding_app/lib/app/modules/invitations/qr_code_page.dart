import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/guest.dart';
import 'invitations_controller.dart';

class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvitationsController>();
    final guest = Get.arguments as Guest;

    // Generate web URL for QR code
    final qrData = 'https://votre-domaine/#/guest/${guest.qrToken}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('QR Code', style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold accent top
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        colors: [AppColors.tertiaryFixed, AppColors.secondaryFixed],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Guest name
                        Text(
                          guest.fullName,
                          style: AppTextStyles.headlineMd,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guest.qrToken,
                          style: AppTextStyles.bodyMdOnVariant,
                        ),
                        const SizedBox(height: 24),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBright,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.tertiaryFixed,
                              width: 2,
                            ),
                          ),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: AppColors.surfaceBright,
                            eyeStyle: const QrEyeStyle(
                              eyeColor: AppColors.onSurface,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleColor: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Invitation code
                        FutureBuilder(
                          future: controller.getInvitationForGuest(guest.id),
                          builder: (context, snapshot) {
                            final invitation = snapshot.data;
                            return Text(
                              invitation?.invitationCode ?? 'INV-XXXX-XXXX',
                              style: AppTextStyles.labelMd.copyWith(
                                letterSpacing: 0.1,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Get.snackbar('Info', 'Fonctionnalité de partage à venir');
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Partager'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondaryContainer,
                                  side: const BorderSide(
                                    color: AppColors.secondaryContainer,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.snackbar('Info', 'Fonctionnalité de téléchargement à venir');
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Télécharger'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
