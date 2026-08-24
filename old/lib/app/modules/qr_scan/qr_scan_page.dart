import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/app_config.dart';
import '../../routes/app_routes.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _handled = false;
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un QR code')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: kIsWeb
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Le scan camera depend du navigateur. Vous pouvez aussi coller le lien ou le token ci-dessous.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : MobileScanner(
                          onDetect: (capture) {
                            if (_handled) {
                              return;
                            }

                            final barcode = capture.barcodes.isNotEmpty
                                ? capture.barcodes.first.rawValue
                                : null;
                            if (barcode == null) {
                              return;
                            }

                            final token = _extractToken(barcode);
                            if (token == null) {
                              return;
                            }

                            _handled = true;
                            Get.offNamed(AppRoutes.guest(token));
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _manualController,
              decoration: const InputDecoration(
                labelText: 'Lien web, deep link ou token',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final token = _extractToken(_manualController.text.trim());
                if (token == null || token.isEmpty) {
                  Get.snackbar(
                    'Token invalide',
                    'Collez un lien /guest/{token} ou un token brut.',
                  );
                  return;
                }

                Get.offNamed(AppRoutes.guest(token));
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractToken(String value) {
    if (value.isEmpty) {
      return null;
    }

    if (!value.contains('://') && !value.contains('/')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }

    return AppConfig.extractToken(uri);
  }
}
