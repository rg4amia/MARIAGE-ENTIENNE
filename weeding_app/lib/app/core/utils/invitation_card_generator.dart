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
    return RepaintBoundary(
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF8B2F00)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top decoration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == 1 ? 8 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'VOUS ÊTES INVITÉ(E)',
              style: AppTextStyles.labelMd.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Guest name
            Text(
              guestName,
              style: AppTextStyles.headlineLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Divider
            Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            // Table & Seat info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CardInfo(
                  icon: Icons.table_restaurant_rounded,
                  label: 'TABLE',
                  value: tableName,
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _CardInfo(
                  icon: Icons.event_seat_rounded,
                  label: 'PLACE',
                  value: seatNumber,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Divider
            Container(height: 1, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            // QR Code
            if (showQrCode && qrToken != null && qrToken!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: qrToken!,
                  version: QrVersions.auto,
                  size: 120,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Footer
            Text(
              '💍 Montrer ce badge à l\'entrée 💍',
              style: AppTextStyles.labelMd.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
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
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.titleLg.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
