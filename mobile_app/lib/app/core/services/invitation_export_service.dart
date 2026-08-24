import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../data/models/invitation_models.dart';

class InvitationAssetBundle {
  const InvitationAssetBundle({
    required this.pngBytes,
    required this.pdfBytes,
    required this.pngFileName,
    required this.pdfFileName,
  });

  final Uint8List pngBytes;
  final Uint8List pdfBytes;
  final String pngFileName;
  final String pdfFileName;
}

class InvitationExportService {
  Future<InvitationAssetBundle> generateAssets({
    required WeddingEvent event,
    required GuestInvitation invitation,
  }) async {
    final pngBytes = await _buildPng(event: event, invitation: invitation);
    final pdfBytes = await _buildPdf(event: event, invitation: invitation);
    final safeCode = invitation.invitationCode.toLowerCase();

    return InvitationAssetBundle(
      pngBytes: pngBytes,
      pdfBytes: pdfBytes,
      pngFileName: 'invitation-$safeCode.png',
      pdfFileName: 'invitation-$safeCode.pdf',
    );
  }

  Future<void> shareAssets(InvitationAssetBundle assets) {
    return SharePlus.instance.share(
      ShareParams(
        text: 'Carte d\'invitation numerique.',
        files: [
          XFile.fromData(assets.pngBytes, mimeType: 'image/png'),
          XFile.fromData(assets.pdfBytes, mimeType: 'application/pdf'),
        ],
        fileNameOverrides: [assets.pngFileName, assets.pdfFileName],
      ),
    );
  }

  Future<Uint8List> _buildPng({
    required WeddingEvent event,
    required GuestInvitation invitation,
  }) async {
    const size = Size(1200, 1800);
    final exportSubtitle = '${event.location} - ${event.eventDateLabel}';
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1200, 1800));

    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [Color(0xFFF7F0E8), Color(0xFFE3C09B), Color(0xFFD48D63)],
        const [0, 0.56, 1],
      );

    canvas.drawRect(const Rect.fromLTWH(0, 0, 1200, 1800), backgroundPaint);

    final circlePaint = Paint()..color = const Color(0x33FFFFFF);
    canvas.drawCircle(const Offset(180, 220), 160, circlePaint);
    canvas.drawCircle(const Offset(1040, 1520), 220, circlePaint);

    _drawText(
      canvas,
      'Invitation de Mariage',
      const Offset(100, 180),
      56,
      const Color(0xFF5C2A12),
      FontWeight.w700,
    );
    _drawText(
      canvas,
      event.coupleLabel,
      const Offset(100, 280),
      88,
      const Color(0xFF7A3516),
      FontWeight.w700,
    );
    _drawText(
      canvas,
      exportSubtitle,
      const Offset(100, 400),
      34,
      const Color(0xFF70442E),
      FontWeight.w500,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 560, 1040, 760),
        const Radius.circular(44),
      ),
      Paint()..color = const Color(0xCCFFF8F1),
    );

    _drawText(
      canvas,
      invitation.guestName.toUpperCase(),
      const Offset(130, 640),
      52,
      const Color(0xFF402214),
      FontWeight.w700,
    );
    _drawText(
      canvas,
      'Table ${invitation.tableLabel}',
      const Offset(130, 770),
      42,
      const Color(0xFF76452A),
      FontWeight.w600,
    );
    _drawText(
      canvas,
      'Chaise ${invitation.chairNumber}',
      const Offset(130, 850),
      42,
      const Color(0xFF76452A),
      FontWeight.w600,
    );
    _drawText(
      canvas,
      'Code invitation: ${invitation.invitationCode}',
      const Offset(130, 950),
      30,
      const Color(0xFF8A5B41),
      FontWeight.w500,
    );
    _drawText(
      canvas,
      invitation.isUnlocked
          ? 'Carte activee apres validation media'
          : 'Carte verrouillee jusqu\'a reception d\'un media valide de 30s',
      const Offset(130, 1080),
      28,
      const Color(0xFF5A3828),
      FontWeight.w500,
      maxWidth: 900,
    );

    _drawText(
      canvas,
      'Route web: ${invitation.webUrl}',
      const Offset(100, 1400),
      26,
      const Color(0xFF5C2A12),
      FontWeight.w500,
      maxWidth: 980,
    );
    _drawText(
      canvas,
      'Deep link: ${invitation.deepLink}',
      const Offset(100, 1470),
      26,
      const Color(0xFF5C2A12),
      FontWeight.w500,
      maxWidth: 980,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<Uint8List> _buildPdf({
    required WeddingEvent event,
    required GuestInvitation invitation,
  }) async {
    final exportSubtitle = '${event.location} - ${event.eventDateLabel}';
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(36),
            decoration: pw.BoxDecoration(
              gradient: const pw.LinearGradient(
                colors: [
                  PdfColor.fromInt(0xFFF7F0E8),
                  PdfColor.fromInt(0xFFE5C59D),
                ],
              ),
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Invitation de Mariage',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF5C2A12),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  event.coupleLabel,
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF7A3516),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  exportSubtitle,
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Spacer(),
                pw.Text(
                  invitation.guestName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Table: ${invitation.tableLabel}'),
                pw.Text('Chaise: ${invitation.chairNumber}'),
                pw.Text('Code: ${invitation.invitationCode}'),
                pw.SizedBox(height: 18),
                pw.Text('Acces web: ${invitation.webUrl}'),
                pw.Text('Deep link: ${invitation.deepLink}'),
                pw.SizedBox(height: 18),
                pw.Text(
                  invitation.isUnlocked
                      ? 'Invitation deblocquee'
                      : 'Invitation verrouillee jusqu\'a validation du media',
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
    FontWeight weight, {
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
    )..layout(maxWidth: maxWidth ?? double.infinity);

    painter.paint(canvas, offset);
  }
}
