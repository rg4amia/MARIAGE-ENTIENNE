import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/entrance_qr.dart';
import '../../data/repositories/entrance_repository.dart';

class EntranceQrPage extends StatefulWidget {
  const EntranceQrPage({super.key});

  @override
  State<EntranceQrPage> createState() => _EntranceQrPageState();
}

class _EntranceQrPageState extends State<EntranceQrPage> {
  final EntranceRepository _repository = EntranceRepository();
  EntranceQr? _entranceQr;
  bool _isLoading = true;
  RealtimeChannel? _changes;

  @override
  void initState() {
    super.initState();
    _load();
    _changes = Supabase.instance.client
        .channel('entrance-check-ins')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'guest_check_ins',
          callback: (_) => _load(silent: true),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'event_entrance_codes',
          callback: (_) => _load(silent: true),
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _changes;
    if (channel != null) Supabase.instance.client.removeChannel(channel);
    super.dispose();
  }

  Future<void> _load({bool silent = false, bool rotate = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final qr = await _repository.getOrCreate(rotate: rotate);
      if (mounted) {
        setState(() => _entranceQr = qr);
      }
    } catch (error) {
      if (mounted) {
        Get.snackbar('Erreur', 'Impossible de charger le QR d’entrée');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = _entranceQr;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('QR d’entrée', style: AppTextStyles.headlineMdPrimary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _isLoading && qr == null
          ? const Center(child: CircularProgressIndicator())
          : qr == null
          ? const Center(child: Text('QR d’entrée indisponible'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'À afficher à l’entrée',
                            style: AppTextStyles.titleLg,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les invités scannent ce QR avec leur téléphone pour confirmer leur arrivée.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMdOnVariant,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outlineVariant,
                              ),
                            ),
                            child: QrImageView(data: qr.url, size: 240),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(qr.code, style: AppTextStyles.labelMd),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Share.share(qr.url),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Partager'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: qr.url),
                                    );
                                    Get.snackbar(
                                      'Copié',
                                      'Lien du QR d’entrée copié',
                                    );
                                  },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copier'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _EntranceStat(
                          label: 'Scans',
                          value: qr.scanCount,
                          icon: Icons.qr_code_scanner,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EntranceStat(
                          label: 'Entrées validées',
                          value: qr.checkInCount,
                          icon: Icons.how_to_reg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _confirmRotation(context),
                    icon: const Icon(Icons.autorenew),
                    label: const Text('Générer un nouveau QR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _confirmRotation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Renouveler le QR ?'),
        content: const Text(
          'L’ancien QR ne fonctionnera plus. Les arrivées déjà enregistrées seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _load(rotate: true);
            },
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
  }
}

class _EntranceStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _EntranceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text('$value', style: AppTextStyles.headlineMdPrimary),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMd,
            ),
          ],
        ),
      ),
    );
  }
}
