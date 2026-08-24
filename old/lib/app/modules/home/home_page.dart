import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/wedding_bottom_nav.dart';
import '../../core/widgets/wedding_cards.dart';
import '../../core/widgets/wedding_top_bar.dart';
import '../../data/models/invitation_models.dart';
import '../../routes/app_routes.dart';
import 'home_controller.dart';

/// Page "Tableau de bord - Maries" reproduisant le design Stitch :
/// hero hauteur libre, statistiques bento, actions rapides, liste
/// d'activite recente, citation editoriale.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = Get.put(HomeController());

  final _tableNameController = TextEditingController();
  final _tableCapacityController = TextEditingController(text: '8');
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _guestEmailController = TextEditingController();

  final Map<String, String?> _selectedChairByGuest = {};

  @override
  void dispose() {
    _tableNameController.dispose();
    _tableCapacityController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _guestEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: WeddingTopBar(
        actions: [
          IconButton(
            tooltip: 'Scanner un QR code',
            onPressed: () => Get.toNamed(AppRoutes.qrScanner),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      bottomNavigationBar: WeddingBottomNav(
        current: WeddingNavItem.dashboard,
        onTap: (item) {
          switch (item) {
            case WeddingNavItem.tables:
              Get.toNamed(AppRoutes.tables);
              break;
            case WeddingNavItem.dashboard:
            case WeddingNavItem.guests:
            case WeddingNavItem.invitations:
              break;
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.isAdminDemoMode) ...[
              _BackendModeNotice(controller: controller),
              const SizedBox(height: 18),
            ],
            const _HeroIntro(),
            const SizedBox(height: 24),
            _StatsBento(controller: controller),
            const SizedBox(height: 28),
            const _SectionTitle('Actions Rapides'),
            const SizedBox(height: 14),
            _QuickActions(
              onAddGuest: _focusGuestForm,
              onAddTable: _focusTableForm,
              onQr: () => Get.toNamed(AppRoutes.qrScanner),
              onTables: () => Get.toNamed(AppRoutes.tables),
            ),
            const SizedBox(height: 24),
            _Quote(controller: controller),
            const SizedBox(height: 28),
            const _SectionTitle('Activite Recente'),
            const SizedBox(height: 14),
            _ActivityList(controller: controller),
            const SizedBox(height: 28),
            const _SectionTitle('Creation Rapide'),
            const SizedBox(height: 14),
            _CreationPanel(
              tableNameController: _tableNameController,
              tableCapacityController: _tableCapacityController,
              guestNameController: _guestNameController,
              guestPhoneController: _guestPhoneController,
              guestEmailController: _guestEmailController,
              onCreateTable: () async {
                final label = _tableNameController.text.trim();
                final capacity = int.tryParse(
                  _tableCapacityController.text.trim(),
                );
                if (label.isEmpty || capacity == null || capacity <= 0) {
                  Get.snackbar(
                    'Informations manquantes',
                    'Entrez un nom de table et une capacite valide.',
                  );
                  return;
                }
                await controller.createTable(label: label, capacity: capacity);
                _tableNameController.clear();
                _tableCapacityController.text = '8';
              },
              onCreateGuest: () async {
                final name = _guestNameController.text.trim();
                if (name.isEmpty) {
                  Get.snackbar('Nom requis', 'Ajoutez le nom de l\'invite.');
                  return;
                }
                await controller.createGuest(
                  fullName: name,
                  phone: _guestPhoneController.text.trim(),
                  email: _guestEmailController.text.trim(),
                );
                _guestNameController.clear();
                _guestPhoneController.clear();
                _guestEmailController.clear();
              },
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Attribution des places'),
            const SizedBox(height: 14),
            _GuestsAssignment(
              controller: controller,
              selectedByGuest: _selectedChairByGuest,
              onSelect: (id, value) =>
                  setState(() => _selectedChairByGuest[id] = value),
            ),
            const SizedBox(height: 28),
            const _SectionTitle('Invitations generees'),
            const SizedBox(height: 14),
            _InvitationsList(controller: controller),
            if (kIsWeb) ...[
              const SizedBox(height: 24),
              GlowCard(
                color: AppColors.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EyebrowLabel('Mode web actif'),
                    const SizedBox(height: 8),
                    Text(
                      'La route /guest/:token fonctionne sur Flutter web. Les deep links mobiles restent disponibles via mariageentienne://guest/{token}.',
                      style: GoogleFonts.manrope(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _focusGuestForm() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _focusTableForm() {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EyebrowLabel('Espace prive'),
        const SizedBox(height: 10),
        Text(
          'Tableau de Bord\nMaries',
          style: GoogleFonts.notoSerif(
            color: AppColors.primary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenue dans votre espace de planification haut de gamme.',
          style: GoogleFonts.manrope(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _BackendModeNotice extends StatelessWidget {
  const _BackendModeNotice({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: AppColors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Mode backend'),
          const SizedBox(height: 8),
          Text(
            controller.isRemoteConfigured
                ? "Le parcours invite est branche au backend Supabase. L'espace maries reste en mode demo local tant qu'aucune session admin n'est ouverte."
                : 'Supabase n\'est pas configure. Toutes les donnees affichees ici restent locales.',
            style: GoogleFonts.manrope(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBento extends StatelessWidget {
  const _StatsBento({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final guestCount = controller.guests.length;
      final assigned = controller.tables.fold<int>(
        0,
        (sum, table) => sum + table.occupiedSeats,
      );
      final unlocked = controller.unlockedCards;
      final tablesFull = controller.tables
          .where(
            (table) =>
                table.capacity > 0 && table.occupiedSeats >= table.capacity,
          )
          .length;

      return Column(
        children: [
          StatBentoCard(
            label: 'Invites confirmes',
            value: '$assigned',
            suffix: '/ $guestCount',
            progress: guestCount == 0 ? 0 : assigned / guestCount,
            icon: Icons.group,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatBentoCard(
                  label: 'Medias recus',
                  value: '$unlocked',
                  suffix: '/ $guestCount',
                  icon: Icons.photo_library,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StatBentoCard(
                  label: 'Tables completes',
                  value: '$tablesFull',
                  suffix: '/ ${controller.tables.length}',
                  icon: Icons.table_bar,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.notoSerif(
        color: AppColors.primary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddGuest,
    required this.onAddTable,
    required this.onQr,
    required this.onTables,
  });

  final VoidCallback onAddGuest;
  final VoidCallback onAddTable;
  final VoidCallback onQr;
  final VoidCallback onTables;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GradientButton(
          label: 'Ajouter un invite',
          icon: Icons.person_add,
          expand: true,
          onPressed: onAddGuest,
        ),
        const SizedBox(height: 12),
        _OutlineAction(
          label: 'Creer une table',
          icon: Icons.grid_view,
          onTap: onAddTable,
        ),
        const SizedBox(height: 12),
        _OutlineAction(
          label: 'Generer un QR code',
          icon: Icons.qr_code_2,
          onTap: onQr,
        ),
        const SizedBox(height: 12),
        _OutlineAction(
          label: 'Ouvrir la salle (Tables)',
          icon: Icons.event_seat,
          onTap: onTables,
        ),
      ],
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Icon(icon, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  const _Quote({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            top: -8,
            right: -8,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.auto_awesome,
                size: 88,
                color: AppColors.primary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"L\'amour est le seul tresor qui se multiplie par le partage."',
                style: GoogleFonts.notoSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 17,
                  color: AppColors.primary.withValues(alpha: 0.78),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '— ${controller.event.coupleLabel}'.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final recentInvitations = controller.invitations
          .take(5)
          .toList(growable: false);

      if (recentInvitations.isEmpty) {
        return GlowCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucune activite pour le moment.',
              style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
            ),
          ),
        );
      }

      return GlowCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ...recentInvitations.asMap().entries.map((entry) {
              final index = entry.key;
              final invitation = entry.value;
              final isLast = index == recentInvitations.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0x14E0BFBF)),
                        ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: invitation.isUnlocked
                            ? AppColors.secondaryContainer.withValues(
                                alpha: 0.3,
                              )
                            : AppColors.surfaceContainerLow,
                      ),
                      child: Icon(
                        invitation.isUnlocked
                            ? Icons.check_circle
                            : Icons.hourglass_top,
                        color: invitation.isUnlocked
                            ? AppColors.secondary
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.guestName,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invitation.isUnlocked
                                ? 'Carte deverrouillee'
                                : 'En attente du media',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          controller.openGuestAccess(invitation.token),
                      icon: const Icon(
                        Icons.play_circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _CreationPanel extends StatelessWidget {
  const _CreationPanel({
    required this.tableNameController,
    required this.tableCapacityController,
    required this.guestNameController,
    required this.guestPhoneController,
    required this.guestEmailController,
    required this.onCreateTable,
    required this.onCreateGuest,
  });

  final TextEditingController tableNameController;
  final TextEditingController tableCapacityController;
  final TextEditingController guestNameController;
  final TextEditingController guestPhoneController;
  final TextEditingController guestEmailController;
  final VoidCallback onCreateTable;
  final VoidCallback onCreateGuest;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('Nouvelle table'),
          const SizedBox(height: 10),
          TextField(
            controller: tableNameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la table',
              hintText: 'Ex : Famille de la mariee',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: tableCapacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre de chaises'),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Ajouter la table',
            icon: Icons.add,
            expand: true,
            onPressed: onCreateTable,
          ),
          const Divider(),
          const EyebrowLabel('Nouvel invite'),
          const SizedBox(height: 10),
          TextField(
            controller: guestNameController,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: guestPhoneController,
            decoration: const InputDecoration(labelText: 'Telephone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: guestEmailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onCreateGuest,
            child: const Text('Ajouter un invite'),
          ),
        ],
      ),
    );
  }
}

class _GuestsAssignment extends StatelessWidget {
  const _GuestsAssignment({
    required this.controller,
    required this.selectedByGuest,
    required this.onSelect,
  });

  final HomeController controller;
  final Map<String, String?> selectedByGuest;
  final void Function(String guestId, String? value) onSelect;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final guests = controller.guests.toList(growable: false);

      if (guests.isEmpty) {
        return GlowCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Ajoutez un invite pour commencer.',
              style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
            ),
          ),
        );
      }

      return Column(
        children: guests
            .map((guest) {
              final chairs = controller.availableChairsForGuest(guest);
              final invitation = controller.invitationForGuest(guest.id);
              selectedByGuest.putIfAbsent(
                guest.id,
                () => invitation?.chairId ?? chairs.firstOrNull?.id,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlowCard(
                  color: AppColors.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.fullName,
                        style: GoogleFonts.notoSerif(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${guest.phone} • ${guest.email}',
                        style: GoogleFonts.manrope(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue:
                            chairs.any(
                              (item) => item.id == selectedByGuest[guest.id],
                            )
                            ? selectedByGuest[guest.id]
                            : chairs.firstOrNull?.id,
                        items: chairs
                            .map(
                              (chair) => DropdownMenuItem(
                                value: chair.id,
                                child: Text(
                                  controller.seatLabelFromChairId(chair.id),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => onSelect(guest.id, value),
                        decoration: const InputDecoration(
                          labelText: 'Selectionnez une chaise',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: chairs.isEmpty
                                ? null
                                : () => controller.assignGuest(
                                    guest: guest,
                                    chairId: selectedByGuest[guest.id]!,
                                  ),
                            child: Text(
                              invitation == null
                                  ? 'Generer la carte'
                                  : 'Reattribuer et regenerer',
                            ),
                          ),
                          if (invitation != null)
                            OutlinedButton(
                              onPressed: () =>
                                  controller.openGuestAccess(invitation.token),
                              child: const Text('Ouvrir le parcours'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    });
  }
}

class _InvitationsList extends StatelessWidget {
  const _InvitationsList({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final invitations = controller.invitations.toList(growable: false);

      if (invitations.isEmpty) {
        return GlowCard(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Aucune invitation generee.',
              style: GoogleFonts.manrope(color: AppColors.onSurfaceVariant),
            ),
          ),
        );
      }

      return Column(
        children: invitations
            .map((invitation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.guestName,
                        style: GoogleFonts.notoSerif(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Table ${invitation.tableLabel} • Chaise ${invitation.chairNumber}',
                        style: GoogleFonts.manrope(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InvitationStatus(invitation: invitation),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonal(
                            onPressed: () =>
                                controller.regenerateAssets(invitation.id),
                            child: const Text('Exporter PNG + PDF'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                controller.openGuestAccess(invitation.token),
                            child: const Text('Tester le lien'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    });
  }
}

class _InvitationStatus extends StatelessWidget {
  const _InvitationStatus({required this.invitation});

  final GuestInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final unlocked = invitation.isUnlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked
            ? AppColors.secondaryContainer.withValues(alpha: 0.25)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: unlocked
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            size: 14,
            color: unlocked ? AppColors.secondary : AppColors.outline,
          ),
          const SizedBox(width: 6),
          Text(
            unlocked ? 'Carte deverrouillee' : 'En attente du media',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: unlocked
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
