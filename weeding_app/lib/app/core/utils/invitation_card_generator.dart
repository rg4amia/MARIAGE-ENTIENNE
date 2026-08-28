import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Utility to generate invitation card as PNG image
class InvitationCardGenerator {
  /// Generate invitation card PNG from a GlobalKey
  static Future<Uint8List?> captureCard(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing card: $e');
      return null;
    }
  }

  /// Save captured image to temporary directory and return file path
  static Future<String?> saveToFile(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  /// Share the invitation card image
  static Future<void> shareCard(Uint8List imageBytes, String guestName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invitation_$guestName.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Voici votre carte d\'invitation, $guestName ! 💍');
    } catch (e) {
      debugPrint('Error sharing card: $e');
    }
  }
}

/// Reusable invitation card widget that can be captured as PNG
class InvitationCardWidget extends StatelessWidget {
  final String guestName;
  final String tableName;
  final String seatNumber;
  final String? qrToken;
  final bool showQrCode;

  const InvitationCardWidget({
    super.key,
    required this.guestName,
    required this.tableName,
    required this.seatNumber,
    this.qrToken,
    this.showQrCode = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final onPrimary = palette.primary.computeLuminance() > 0.48
        ? AppColors.dark
        : Colors.white;

    return RepaintBoundary(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.dark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.16),
              blurRadius: 0,
              offset: const Offset(8, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.dark, width: 1.2),
              ),
              child: Text(
                'VOUS ÊTES INVITÉ(E)',
                style: AppTextStyles.labelMd.copyWith(
                  color: palette.secondary.computeLuminance() > 0.48
                      ? AppColors.dark
                      : Colors.white,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              guestName,
              style: AppTextStyles.headlineLg.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.dark, width: 1.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CardInfo(
                    icon: Icons.table_restaurant_rounded,
                    label: 'TABLE',
                    value: tableName,
                  ),
                  Container(width: 1, height: 50, color: AppColors.dark),
                  _CardInfo(
                    icon: Icons.event_seat_rounded,
                    label: 'PLACE',
                    value: seatNumber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (showQrCode && qrToken != null && qrToken!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dark, width: 1.4),
                ),
                child: QrImageView(
                  data: qrToken!,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: AppColors.dark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppColors.dark,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              '💍 Montrer ce badge à l\'entrée 💍',
              style: AppTextStyles.labelMd.copyWith(
                color: onPrimary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.dark, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleLg.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
