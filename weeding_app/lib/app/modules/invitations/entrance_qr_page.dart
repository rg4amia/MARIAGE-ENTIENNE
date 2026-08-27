import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/models/entrance_qr.dart';
import '../../data/repositories/entrance_repository.dart';

class EntranceQrPage extends StatefulWidget {
  const EntranceQrPage({super.key});

  @override
  State<EntranceQrPage> createState() => _EntranceQrPageState();
}

class _EntranceQrPageState extends State<EntranceQrPage>
    with SingleTickerProviderStateMixin {
  final EntranceRepository _repository = EntranceRepository();
  EntranceQr? _entranceQr;
  bool _isLoading = true;
  RealtimeChannel? _changes;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
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
    _pulseCtrl.dispose();
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
    } catch (error, stackTrace) {
      debugPrint('Erreur QR entrée: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Retry once after refreshing JWT (may lack app_metadata.role)
      try {
        await Supabase.instance.client.auth.refreshSession();
        final qr = await _repository.getOrCreate(rotate: rotate);
        if (mounted) {
          setState(() => _entranceQr = qr);
        }
      } catch (retryError) {
        debugPrint('Erreur QR entrée (retry): $retryError');
        if (mounted) {
          Get.snackbar(
            'Erreur',
            'QR indisponible — vérifiez votre connexion et reconnectez-vous.',
          );
        }
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
      body: _isLoading && qr == null
          ? const Center(child: CircularProgressIndicator())
          : qr == null
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    // ── Gradient Header ──
                    SliverToBoxAdapter(
                      child: WeddingHeader(
                        title: "QR d'entrée",
                        trailing: TapScale(
                          onTap: _load,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        child: HeaderInfoBanner(
                          icon: Icons.info_outline_rounded,
                          text: "Affichez ce QR à l'entrée — les invités le scannent pour confirmer leur arrivée.",
                        ),
                      ),
                    ),
                    // ── QR Code Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: FadeInSlide(
                          delay: const Duration(milliseconds: 200),
                          child: _buildQrCard(qr),
                        ),
                      ),
                    ),
                    // ── Stats Row ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: FadeInSlide(
                          delay: const Duration(milliseconds: 350),
                          child: _buildStatsRow(qr),
                        ),
                      ),
                    ),
                    // ── Actions ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: FadeInSlide(
                          delay: const Duration(milliseconds: 500),
                          child: _buildActions(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 40,
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text('QR d\'entrée indisponible',
              style: AppTextStyles.headlineMd),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur ⟳ pour réessayer',
            style: AppTextStyles.bodyMdOnVariant,
          ),
          const SizedBox(height: 24),
          TapScale(
            onTap: () => _load(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Réessayer',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── QR Code Card with Decorative Frame ──
  Widget _buildQrCard(EntranceQr qr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Title
          Text(
            'Scan pour arrivée',
            style: AppTextStyles.titleLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          // QR with decorative frame
          ScaleIn(
            delay: const Duration(milliseconds: 400),
            child: _buildDecorativeQrFrame(qr),
          ),
          const SizedBox(height: 16),
          // Code display
          _buildCodeChip(qr.code),
          const SizedBox(height: 20),
          // Share / Copy buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: () => Share.share(qr.url),
                    child: _buildActionChip(
                      icon: Icons.share_rounded,
                      label: 'Partager',
                      isPrimary: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TapScale(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: qr.url));
                      HapticFeedback.lightImpact();
                      Get.snackbar('Copié', 'Lien du QR d\'entrée copié');
                    },
                    child: _buildActionChip(
                      icon: Icons.copy_rounded,
                      label: 'Copier',
                      isPrimary: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Decorative QR Frame ──
  Widget _buildDecorativeQrFrame(EntranceQr qr) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final glowOpacity = 0.08 + (_pulseCtrl.value * 0.07);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glowOpacity),
                blurRadius: 24 + (_pulseCtrl.value * 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: QrImageView(
            data: qr.url,
            size: 220,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Color(0xFFA53C00),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Color(0xFF3D3028),
            ),
          ),
        );
      },
    );
  }

  // ── Code Chip ──
  Widget _buildCodeChip(String code) {
    // Truncate long codes for display
    final displayCode =
        code.length > 16 ? '${code.substring(0, 8)}···${code.substring(code.length - 8)}' : code;
    return TapScale(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        HapticFeedback.lightImpact();
        Get.snackbar('Copié', 'Code copié dans le presse-papier');
      },
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag_rounded,
                size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            SelectableText(
              displayCode,
              style: AppTextStyles.labelMd.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.content_copy_rounded,
                size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // ── Action Chip (Partager / Copier) ──
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFA53C00), Color(0xFFFF7A3D)],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary
            ? null
            : Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isPrimary ? Colors.white : AppColors.primary,
              size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow(EntranceQr qr) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.qr_code_scanner_rounded,
            value: qr.scanCount,
            label: 'Scans',
            gradient: const [
              Color(0xFFFF7A3D),
              Color(0xFFFFB598),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.how_to_reg_rounded,
            value: qr.checkInCount,
            label: 'Entrées',
            gradient: const [
              Color(0xFF4CAF50),
              Color(0xFF81C784),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int value,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 12),
          AnimatedCounter(
            target: value,
            style: AppTextStyles.headlineLgMobile.copyWith(
              color: gradient.first,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Actions ──
  Widget _buildActions() {
    return TapScale(
      onTap: () => _confirmRotation(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Text(
              'Générer un nouveau QR',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm Rotation Dialog ──
  void _confirmRotation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Renouveler le QR ?'),
        content: const Text(
          'L\'ancien QR ne fonctionnera plus. '
          'Les arrivées déjà enregistrées seront conservées.',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
String entranceQrErrorMessage(Object error) {
  if (error is PostgrestException) {
    if (error.message.contains('No wedding event is attached')) {
      return 'Votre compte administrateur n’est associé à aucun mariage.';
    }
    if (error.message.contains('Administrator access required')) {
      return 'Accès administrateur requis. Reconnectez-vous.';
    }

    return 'Erreur Supabase (${error.code ?? 'inconnue'}) : ${error.message}';
  }

  if (error is AuthException) {
    return 'Votre session a expiré. Reconnectez-vous.';
  }

  return 'Impossible de charger le QR. Réessayez dans quelques instants.';
}
