import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/platform_admin.dart';
import 'admin_controller.dart';

/// Console d'exploitation : comptes, mariages et gestes commerciaux.
/// Réservée aux exploitants du service ; la base refuse tout le reste.
class AdminConsolePage extends StatelessWidget {
  const AdminConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text('Console exploitant', style: AppTextStyles.titleLg),
          actions: [
            IconButton(
              tooltip: 'Rafraîchir',
              onPressed: controller.loadAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Organisations'),
              Tab(text: 'Mariages'),
              Tab(text: 'Comptes'),
              Tab(text: 'Journal'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une organisation, un mariage, un e-mail',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
                onSubmitted: (value) {
                  controller.search.value = value;
                  controller.loadAll();
                },
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.errorMessage.isNotEmpty) {
                  return _Message(text: controller.errorMessage.value);
                }
                return TabBarView(
                  children: [
                    _OrganizationsTab(controller: controller),
                    _EventsTab(controller: controller),
                    _AccountsTab(controller: controller),
                    _JournalTab(controller: controller),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationsTab extends StatelessWidget {
  const _OrganizationsTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.organizations;
    if (rows.isEmpty) return const _Message(text: 'Aucune organisation.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final org = rows[index];
        return _Card(
          title: org.name,
          subtitle: org.ownerEmail ?? 'Propriétaire inconnu',
          badge: _Badge(
            label: org.statusLabel,
            danger: org.isBlocked,
          ),
          lines: [
            'Forfait : ${org.planName ?? "aucun"}',
            '${org.events} mariage(s) · ${org.members} membre(s)',
            '${org.guests} invité(s) · ${org.invitationsSent} envoi(s)',
          ],
          actions: [
            TextButton(
              onPressed: () => _changePlan(context, org),
              child: const Text('Changer de forfait'),
            ),
            TextButton(
              onPressed: () => _changeStatus(context, org),
              child: Text(org.isBlocked ? 'Réactiver' : 'Suspendre'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePlan(BuildContext context, AdminOrganization org) async {
    final plans = controller.availablePlans;
    if (plans.isEmpty) return;

    var selected = org.planId ?? plans.first.id;
    final reason = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Forfait de ${org.name}', style: AppTextStyles.titleLg),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected,
                items: plans
                    .map(
                      (plan) => DropdownMenuItem(
                        value: plan.id,
                        child: Text('${plan.name} — ${plan.formattedAmount}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => selected = value ?? selected),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reason,
                decoration: const InputDecoration(
                  labelText: 'Motif (obligatoire, journalisé)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.setPlan(org.id, selected, reason.text);
    }
  }

  Future<void> _changeStatus(
    BuildContext context,
    AdminOrganization org,
  ) async {
    final target = org.isBlocked ? 'active' : 'suspended';
    final reason = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          org.isBlocked ? 'Réactiver ${org.name}' : 'Suspendre ${org.name}',
          style: AppTextStyles.titleLg,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              org.isBlocked
                  ? 'Le compte pourra de nouveau envoyer ses invitations.'
                  : 'Le compte ne pourra plus envoyer d\'invitation tant '
                        'qu\'il sera suspendu.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire, journalisé)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: Text(org.isBlocked ? 'Réactiver' : 'Suspendre'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.setStatus(org.id, target, reason.text);
    }
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.events;
    if (rows.isEmpty) return const _Message(text: 'Aucun mariage.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final event = rows[index];
        return _Card(
          title: event.title,
          subtitle: event.organizationName,
          lines: [
            '${event.guests} invité(s) · ${event.tables} table(s)',
            'Envois : ${event.quotaLabel}',
          ],
          actions: [
            TextButton(
              onPressed: () => _grant(context, event),
              child: const Text('Offrir des envois'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _grant(BuildContext context, AdminEvent event) async {
    final amount = TextEditingController(text: '10');
    final reason = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Offrir des envois', style: AppTextStyles.titleLg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Le crédit relève la limite du mariage « ${event.title} ». '
              'Les envois déjà consommés ne sont pas effacés.',
              style: AppTextStyles.bodyMd,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nombre d\'envois'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reason,
              decoration: const InputDecoration(
                labelText: 'Motif (obligatoire, journalisé)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Offrir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.grantInvitations(
        event.id,
        int.tryParse(amount.text) ?? 0,
        reason.text,
      );
    }
  }
}

class _AccountsTab extends StatelessWidget {
  const _AccountsTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.accounts;
    if (rows.isEmpty) return const _Message(text: 'Aucun compte.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final account = rows[index];
        return _Card(
          title: account.email ?? 'Compte sans e-mail',
          subtitle: account.memberships.isEmpty
              ? 'Aucune organisation'
              : account.memberships
                    .map((m) => '${m.organizationName} (${m.role})')
                    .join(' · '),
          badge: account.isPlatformAdmin
              ? const _Badge(label: 'Exploitant')
              : null,
          lines: [
            if (account.neverSignedIn)
              'Jamais connecté'
            else
              'Dernière connexion : ${_day(account.lastSignInAt)}',
          ],
        );
      },
    );
  }
}

class _JournalTab extends StatelessWidget {
  const _JournalTab({required this.controller});

  final AdminController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.actions;
    if (rows.isEmpty) {
      return const _Message(text: 'Aucun geste d\'exploitation enregistré.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final action = rows[index];
        return _Card(
          title: action.label,
          subtitle: action.summary,
          lines: [
            '${action.actorEmail ?? "Exploitant"} · ${_day(action.createdAt)}',
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.subtitle,
    required this.lines,
    this.badge,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<String> lines;
  final Widget? badge;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppTextStyles.titleLg),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(line, style: AppTextStyles.labelMd),
            ),
          ),
          if (actions.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.dark : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMd.copyWith(color: color),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _day(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
