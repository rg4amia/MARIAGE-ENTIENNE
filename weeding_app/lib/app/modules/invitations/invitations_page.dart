import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_nav_bar.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/guest_link_repository.dart';
import '../../data/models/guest.dart';

/// Admin page to track all guest invitation statuses and media submissions.
class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final GuestRepository _guestRepo = GuestRepository();
  final GuestLinkRepository _linkRepo = GuestLinkRepository();

  List<Guest> _guests = [];
  Map<String, int> _linkStats = {};
  bool _isLoading = true;

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
      setState(() {
        _guests = guests;
        _linkStats = stats;
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
      appBar: AppBar(
        title: Text(
          'Suivi des invitations',
          style: AppTextStyles.headlineMdPrimary,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
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
                          color: AppColors.secondary,
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
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
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
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  void _showGuestDetails(Guest guest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
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
              // Guest info
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryFixed,
                    child: Text(
                      guest.initials,
                      style: AppTextStyles.titleLg.copyWith(
                        color: AppColors.primary,
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
              // Status timeline
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
              // Status badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusColor(guest.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'media_uploaded':
        return AppColors.secondary;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      default:
        return AppColors.onTertiaryContainer;
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
            color: AppColors.primary,
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _statusColor(
                  guest.status,
                ).withValues(alpha: 0.15),
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
        return AppColors.secondary;
      case 'card_unlocked':
        return AppColors.statusCardUnlocked;
      default:
        return AppColors.onTertiaryContainer;
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
                    ? AppColors.statusCardUnlocked
                    : isCurrent
                    ? AppColors.primary
                    : AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.statusCardUnlocked
                      : isCurrent
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
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
                    ? AppColors.statusCardUnlocked
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
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
