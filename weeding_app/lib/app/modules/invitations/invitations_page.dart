import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/wedding_header.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/models/guest.dart';
import '../../data/models/guest_media.dart';
import 'media_player_page.dart';

/// Admin page to track all guest invitation statuses and media submissions.
class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final GuestRepository _guestRepo = GuestRepository();
  final GuestLinkRepository _linkRepo = GuestLinkRepository();
  final MediaRepository _mediaRepo = MediaRepository();

  List<Guest> _guests = [];
  Map<String, int> _linkStats = {};
  bool _isLoading = true;
  Map<String, GuestMedia?> _guestMedia = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final guests = await _guestRepo.getAllGuests();
      final stats = await _linkRepo.getLinkStats();
      
      // Fetch media for each guest
      final mediaMap = <String, GuestMedia?>{};
      for (final guest in guests) {
        final media = await _mediaRepo.getValidMediaByGuestId(guest.id);
        mediaMap[guest.id] = media;
      }
      
      setState(() {
        _guests = guests;
        _linkStats = stats;
        _guestMedia = mediaMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Erreur', 'Impossible de charger les données');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _guests.where((g) => g.status == 'pending').length;
    final mediaUploaded = _guests
        .where((g) => g.status == 'media_uploaded')
        .length;
    final cardUnlocked = _guests
        .where((g) => g.status == 'card_unlocked')
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          WeddingHeader(
            title: 'Invitations',
            showBack: false,
            trailing: GestureDetector(
              onTap: _loadData,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.dark,
                  size: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.dark),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats cards
                          Text(
                            'Vue d\'ensemble',
                            style: AppTextStyles.titleLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatCard(
                                title: 'En attente',
                                count: pending,
                                color: AppColors.statusPending,
                                icon: Icons.hourglass_empty,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                title: 'Média reçu',
                                count: mediaUploaded,
                                color: AppColors.statusMediaReceived,
                                icon: Icons.upload_file,
                              ),
                              const SizedBox(width: 12),
                              _StatCard(
                                title: 'Carte débloquée',
                                count: cardUnlocked,
                                color: AppColors.statusCardUnlocked,
                                icon: Icons.check_circle,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Link stats
                          if (_linkStats.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _MiniStat(
                                    label: 'Liens créés',
                                    value: '${_linkStats['totalLinks'] ?? 0}',
                                  ),
                                  _MiniStat(
                                    label: 'Scans totaux',
                                    value: '${_linkStats['totalScans'] ?? 0}',
                                  ),
                                  _MiniStat(
                                    label: 'Taux scan',
                                    value:
                                        '${_linkStats['scannedAtLeastOnce'] ?? 0}/${_linkStats['totalLinks'] ?? 0}',
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Guest list
                          Text(
                            'Détails par invité',
                            style: AppTextStyles.titleLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_guests.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'Aucun invité pour le moment',
                                  style: AppTextStyles.bodyMd.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_guests.length, (index) {
                              final guest = _guests[index];
                              return _GuestStatusCard(
                                guest: guest,
                                onTap: () => _showGuestDetails(guest),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showGuestDetails(Guest guest) {
    final media = _guestMedia[guest.id];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.dark.withValues(alpha: 0.08),
                    child: Text(
                      guest.initials,
                      style: AppTextStyles.titleLg.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(guest.fullName, style: AppTextStyles.titleLg),
                        if (guest.email != null)
                          Text(
                            guest.email!,
                            style: AppTextStyles.bodyMdOnVariant,
                          ),
                        if (guest.phone != null)
                          Text(
                            guest.phone!,
                            style: AppTextStyles.bodyMdOnVariant,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Text('Parcours', style: AppTextStyles.titleLg),
              const SizedBox(height: 16),
              _StatusStep(
                title: 'Invitation créée',
                isCompleted: true,
                isCurrent: guest.status == 'pending',
              ),
              _StatusStep(
                title: 'Lien QR généré',
                isCompleted: true,
                isCurrent: guest.status == 'pending',
              ),
              _StatusStep(
                title: 'Média enregistré',
                isCompleted: guest.status != 'pending',
                isCurrent: guest.status == 'media_uploaded',
              ),
              _StatusStep(
                title: 'Carte débloquée',
                isCompleted: guest.status == 'card_unlocked',
                isCurrent: false,
                isLast: true,
              ),
              const SizedBox(height: 24),
              // Media status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusColor(guest.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _statusColor(guest.status).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusIcon(guest.status),
                      color: _statusColor(guest.status),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.statusLabel,
                            style: AppTextStyles.titleLg.copyWith(
                              color: _statusColor(guest.status),
                            ),
                          ),
                          Text(
                            _statusDescription(guest.status),
                            style: AppTextStyles.bodyMdOnVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Media player button
              if (media != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MediaPlayerPage(
                            guest: guest,
                            media: media,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      media.mediaType == 'video' ? Icons.play_circle : Icons.headphones,
                      size: 20,
                    ),
                    label: Text(
                      media.mediaType == 'video' ? 'Lire la vidéo' : 'Écouter le message',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Media info
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MediaInfo(
                        icon: media.mediaType == 'video' ? Icons.videocam : Icons.mic,
                        label: media.mediaType == 'video' ? 'Vidéo' : 'Audio',
                      ),
                      _MediaInfo(
                        icon: Icons.timer,
                        label: media.durationFormatted,
                      ),
                      _MediaInfo(
                        icon: media.isValid ? Icons.check_circle : Icons.pending,
                        label: media.isValid ? 'Validé' : 'En attente',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'media_uploaded':
        return AppColors.statusMediaReceived;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'media_uploaded':
        return Icons.upload_file;
      case 'card_unlocked':
        return Icons.check_circle;
      default:
        return Icons.hourglass_empty;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'media_uploaded':
        return 'Le média est en cours de traitement';
      case 'card_unlocked':
        return 'L\'invité a accès à sa carte d\'invitation';
      default:
        return 'En attente de l\'enregistrement audio/vidéo';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: AppTextStyles.headlineMd.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.labelMd.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLg.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GuestStatusCard extends StatelessWidget {
  final Guest guest;
  final VoidCallback onTap;

  const _GuestStatusCard({required this.guest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _statusColor(
                  guest.status,
                ).withValues(alpha: 0.12),
                child: Text(
                  guest.initials,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: _statusColor(guest.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest.fullName,
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (guest.email != null)
                      Text(
                        guest.email!,
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(guest.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(guest.status),
                      size: 14,
                      color: _statusColor(guest.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      guest.statusLabel,
                      style: AppTextStyles.labelMd.copyWith(
                        color: _statusColor(guest.status),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'media_uploaded':
        return AppColors.statusMediaReceived;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'media_uploaded':
        return Icons.upload_file;
      case 'card_unlocked':
        return Icons.check_circle;
      default:
        return Icons.hourglass_empty;
    }
  }
}

class _StatusStep extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.isCompleted,
    this.isCurrent = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                    ? AppColors.dark
                    : AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                      ? AppColors.dark
                      : AppColors.outlineVariant,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: AppColors.dark)
                  : isCurrent
                  ? Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            title,
            style: AppTextStyles.bodyMd.copyWith(
              color: isCompleted
                  ? AppColors.onSurface
                  : isCurrent
                  ? AppColors.dark
                  : AppColors.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MediaInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
