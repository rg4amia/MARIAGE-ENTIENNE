import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../data/models/guest.dart';
import '../../data/repositories/wedding_settings_repository.dart';
import 'whatsapp_helper.dart';

/// Feuille « Envoyer l'invitation » : le couple choisit le canal selon les
/// coordonnées de l'invité (WhatsApp si téléphone, e-mail si adresse,
/// partage système ou copie du lien dans tous les cas).
Future<void> showInvitationSendSheet({
  required BuildContext context,
  required Guest guest,
}) async {
  WeddingSettings? settings;
  try {
    settings = await WeddingSettingsRepository().getSettings();
  } catch (_) {
    settings = null;
  }
  if (!context.mounted) return;

  final phone = guest.phone?.trim() ?? '';
  final email = guest.email?.trim() ?? '';
  final message = invitationMessageForGuest(guest: guest, settings: settings);
  // Version lisible hors WhatsApp : le gras `*...*` est retiré.
  final plainMessage = message.replaceAll('*', '');
  final subject = invitationEmailSubject(settings);
  final link = invitationLinkForGuest(guest);
  final firstName = guest.fullName.split(' ').first;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text(
                'Envoyer l\'invitation à $firstName',
                style: AppTextStyles.headlineMd,
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez le canal selon les coordonnées de l\'invité.',
                style: AppTextStyles.bodyMdOnVariant,
              ),
              const SizedBox(height: 16),
              if (phone.isNotEmpty) ...[
                _ChannelTile(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF25D366),
                  title: 'WhatsApp',
                  subtitle: phone,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final sent = await sendWeddingInvitationWhatsApp(
                      guest: guest,
                      settings: settings,
                    );
                    Get.snackbar(
                      sent ? '✅ Envoyé' : '⚠️ Annulé',
                      sent
                          ? 'Invitation ouverte dans WhatsApp pour ${guest.fullName}'
                          : 'WhatsApp n\'est pas disponible ou l\'envoi a été annulé',
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (email.isNotEmpty) ...[
                _ChannelTile(
                  icon: Icons.mail_outline_rounded,
                  iconColor: AppColors.dark,
                  title: 'E-mail',
                  subtitle: email,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri(
                      scheme: 'mailto',
                      path: email,
                      queryParameters: {
                        'subject': subject,
                        'body': plainMessage,
                      },
                    );
                    try {
                      final opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!opened) {
                        Get.snackbar(
                          'E-mail indisponible',
                          'Aucune application e-mail n\'a pu être ouverte.',
                        );
                      }
                    } catch (_) {
                      Get.snackbar(
                        'E-mail indisponible',
                        'Aucune application e-mail n\'a pu être ouverte.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
              _ChannelTile(
                icon: Icons.ios_share_rounded,
                iconColor: AppColors.dark,
                title: 'Autres applications',
                subtitle: 'Partager via SMS, messagerie…',
                onTap: () async {
                  Navigator.pop(ctx);
                  await Share.share(plainMessage, subject: subject);
                },
              ),
              const SizedBox(height: 8),
              _ChannelTile(
                icon: Icons.link_rounded,
                iconColor: AppColors.dark,
                title: 'Copier le lien',
                subtitle: link,
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: link));
                  Get.snackbar(
                    'Lien copié !',
                    'Collez-le dans l\'application de votre choix.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ChannelTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ENVOI EN MASSE — invités qui n'ont pas encore répondu
// ═══════════════════════════════════════════════════════

enum _BulkStepResult { sent, passed, aborted }

/// Feuille « Envoyer en masse » : le couple choisit le canal (WhatsApp ou
/// e-mail) puis l'app relance un à un les invités sans réponse, en ouvrant
/// chaque fois l'application avec le message pré-rempli.
Future<void> showBulkInvitationSheet({
  required BuildContext context,
  required List<Guest> guests,
}) async {
  final awaiting = guests
      .where((g) => g.status != 'cancelled' && g.rsvpStatus == 'pending')
      .toList();
  if (awaiting.isEmpty) return;

  final withPhone = awaiting
      .where((g) => (g.phone?.trim() ?? '').isNotEmpty)
      .toList();
  final withEmail = awaiting
      .where((g) => (g.email?.trim() ?? '').isNotEmpty)
      .toList();
  final noContactCount = awaiting
      .where(
        (g) =>
            (g.phone?.trim() ?? '').isEmpty && (g.email?.trim() ?? '').isEmpty,
      )
      .length;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text('Envoyer en masse', style: AppTextStyles.headlineMd),
              const SizedBox(height: 4),
              Text(
                '${awaiting.length} invité(s) n\'ont pas encore répondu.',
                style: AppTextStyles.bodyMdOnVariant,
              ),
              const SizedBox(height: 16),
              if (withPhone.isNotEmpty) ...[
                _ChannelTile(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: const Color(0xFF25D366),
                  title: 'WhatsApp',
                  subtitle: '${withPhone.length} invité(s) par téléphone',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _runGuidedBulkSend(
                      context: context,
                      guests: withPhone,
                      isEmail: false,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (withEmail.isNotEmpty) ...[
                _ChannelTile(
                  icon: Icons.mail_outline_rounded,
                  iconColor: AppColors.dark,
                  title: 'E-mail',
                  subtitle: '${withEmail.length} invité(s) par e-mail',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _runGuidedBulkSend(
                      context: context,
                      guests: withEmail,
                      isEmail: true,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (noContactCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusPending),
                  ),
                  child: Text(
                    '$noContactCount invité(s) sans téléphone ni e-mail ne '
                    'peuvent pas être relancés ici. Ouvrez leur fiche pour '
                    'ajouter une coordonnée.',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.dark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Parcourt la liste des invités : à chaque étape l'app ouvre WhatsApp (ou
/// l'e-mail) avec le message pré-rempli, puis l'utilisateur valide le passage
/// au suivant. Un récapitulatif s'affiche en fin de parcours.
Future<void> _runGuidedBulkSend({
  required BuildContext context,
  required List<Guest> guests,
  required bool isEmail,
}) async {
  if (guests.isEmpty) return;

  WeddingSettings? settings;
  try {
    settings = await WeddingSettingsRepository().getSettings();
  } catch (_) {
    settings = null;
  }

  var sentCount = 0;
  var aborted = false;
  final passedNames = <String>[];

  for (var i = 0; i < guests.length; i++) {
    if (!context.mounted) return;
    final result = await showModalBottomSheet<_BulkStepResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BulkSendStepSheet(
        guest: guests[i],
        index: i,
        total: guests.length,
        settings: settings,
        isEmail: isEmail,
      ),
    );
    if (!context.mounted) return;

    if (result == _BulkStepResult.sent) {
      sentCount++;
    } else if (result == _BulkStepResult.passed) {
      passedNames.add(guests[i].fullName);
    } else {
      aborted = true;
      break;
    }
  }

  if (!context.mounted) return;
  if (aborted) {
    Get.snackbar(
      'Envoi annulé',
      '$sentCount invitation(s) envoyée(s) avant l\'arrêt.',
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _BulkRecapSheet(sentCount: sentCount, passedNames: passedNames),
  );
}

/// Carte d'une étape de l'envoi guidé (un invité).
class _BulkSendStepSheet extends StatefulWidget {
  final Guest guest;
  final int index;
  final int total;
  final WeddingSettings? settings;
  final bool isEmail;

  const _BulkSendStepSheet({
    required this.guest,
    required this.index,
    required this.total,
    required this.settings,
    required this.isEmail,
  });

  @override
  State<_BulkSendStepSheet> createState() => _BulkSendStepSheetState();
}

class _BulkSendStepSheetState extends State<_BulkSendStepSheet> {
  bool _opened = false;
  bool _launching = false;
  String? _error;

  Future<void> _launch() async {
    setState(() {
      _launching = true;
      _error = null;
    });

    var opened = false;
    if (widget.isEmail) {
      final email = widget.guest.email?.trim() ?? '';
      final subject = invitationEmailSubject(widget.settings);
      final body = invitationMessageForGuest(
        guest: widget.guest,
        settings: widget.settings,
      ).replaceAll('*', '');
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: {'subject': subject, 'body': body},
      );
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    } else {
      opened = await sendWeddingInvitationWhatsApp(
        guest: widget.guest,
        settings: widget.settings,
      );
    }

    if (!mounted) return;
    setState(() {
      _launching = false;
      if (opened) {
        _opened = true;
      } else {
        _error = widget.isEmail
            ? "Aucune application e-mail n'a pu être ouverte."
            : "WhatsApp n'est pas disponible ou l'ouverture a été annulée.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.isEmail
        ? widget.guest.email?.trim() ?? ''
        : widget.guest.phone?.trim() ?? '';
    final preview = invitationMessageForGuest(
      guest: widget.guest,
      settings: widget.settings,
    ).replaceAll('*', '');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const SizedBox(height: 16),
            Text(
              'Invité ${widget.index + 1} sur ${widget.total}',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.guest.fullName, style: AppTextStyles.headlineMd),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  widget.isEmail
                      ? Icons.mail_outline_rounded
                      : Icons.phone_outlined,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    contact,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Message à envoyer :',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                preview,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.labelMd.copyWith(color: AppColors.error),
              ),
            ],
            if (_opened) ...[
              const SizedBox(height: 8),
              Text(
                widget.isEmail
                    ? 'Rédaction ouverte : envoyez le message puis revenez ici.'
                    : 'WhatsApp ouvert : envoyez le message puis revenez ici.',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.dark),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _launching
                    ? null
                    : _opened
                    ? () => Navigator.pop(context, _BulkStepResult.sent)
                    : _launch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _launching
                      ? 'Ouverture…'
                      : _opened
                      ? '✅ Envoyé, invité suivant'
                      : widget.isEmail
                      ? "Ouvrir l'e-mail"
                      : 'Ouvrir WhatsApp',
                  style: AppTextStyles.titleLg,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, _BulkStepResult.passed),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.dark,
                  side: BorderSide(
                    color: AppColors.dark.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Passer cet invité'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.pop(context, _BulkStepResult.aborted),
                child: Text(
                  'Annuler l\'envoi groupé',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Récapitulatif affiché en fin d'envoi groupé.
class _BulkRecapSheet extends StatelessWidget {
  final int sentCount;
  final List<String> passedNames;

  const _BulkRecapSheet({required this.sentCount, required this.passedNames});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          Text('Envoi terminé 🎉', style: AppTextStyles.headlineMd),
          const SizedBox(height: 4),
          Text(
            'Les réponses apparaîtront dans l\'onglet Invités.',
            style: AppTextStyles.bodyMdOnVariant,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: AppColors.statusMediaReceived,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$sentCount invitation(s) envoyée(s)',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (passedNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.skip_next_rounded,
                  size: 20,
                  color: AppColors.statusPending,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Passé(s) : ${passedNames.join(', ')}',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Terminer', style: AppTextStyles.titleLg),
            ),
          ),
        ],
      ),
    );
  }
}
