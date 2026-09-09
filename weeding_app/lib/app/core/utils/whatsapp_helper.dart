import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/supabase_config.dart';
import '../../data/models/guest.dart';
import '../../data/repositories/wedding_settings_repository.dart';

/// Sends a wedding invitation message to a guest via WhatsApp.
///
/// Returns `true` if WhatsApp was launched successfully, `false` if
/// the user cancelled or WhatsApp is not available.
Future<bool> sendWeddingInvitationWhatsApp({
  required Guest guest,
  WeddingSettings? settings,
}) async {
  if (guest.phone == null || guest.phone!.isEmpty) return false;

  final phone = _normalizePhone(guest.phone!);
  if (phone.isEmpty) return false;

  final message = _buildInvitationMessage(guest: guest, settings: settings);

  final uri = Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );

  try {
    // canLaunchUrl can be unreliable on some devices — try launching directly.
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched;
  } catch (e) {
    debugPrint('Erreur ouverture WhatsApp: $e');
    // Fallback: try with wa:// scheme (some older WhatsApp versions)
    try {
      final fallback = Uri.parse(
        'wa://send?phone=$phone&text=${Uri.encodeComponent(message)}',
      );
      return await launchUrl(fallback, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Lien public de l'invitation (portail + token de l'invité). Utilisé par le
/// message WhatsApp, l'e-mail, le partage et le bouton « copier le lien ».
String invitationLinkForGuest(Guest guest) {
  return '${SupabaseConfig.guestPortalUrl}?token=${guest.qrToken}';
}

/// Texte d'invitation complet (mise en gras WhatsApp `*...*`).
String invitationMessageForGuest({
  required Guest guest,
  WeddingSettings? settings,
}) {
  return _buildInvitationMessage(guest: guest, settings: settings);
}

/// Sujet court utilisé pour un envoi par e-mail.
String invitationEmailSubject(WeddingSettings? settings) {
  final bride = settings?.brideName ?? '';
  final groom = settings?.groomName ?? '';
  final couple = (bride.isNotEmpty && groom.isNotEmpty)
      ? '$bride & $groom'
      : (settings?.title ?? 'Notre mariage');
  return 'Invitation — $couple';
}

/// Normalizes an Ivorian phone number to the format WhatsApp expects
/// (digits only, starting with the country code 225).
///
/// En Côte d'Ivoire le numéro national comporte 10 chiffres et commence par 0
/// (01/05/07…). `wa.me` attend l'indicatif 225 suivi du numéro national
/// COMPLET, 0 inclus : `0757400462` → `2250757400462`. Retirer ce 0 produit
/// un numéro invalide refusé par WhatsApp (« not a valid phone number »).
String _normalizePhone(String raw) {
  // Remove all non-digit characters
  var digits = raw.replaceAll(RegExp(r'[^\d]'), '');

  // Strip international dialing prefixes (00225… ou 225…).
  if (digits.startsWith('00225')) {
    digits = digits.substring(5);
  } else if (digits.startsWith('225') && digits.length > 10) {
    digits = digits.substring(3);
  }

  // Numéro local (≤ 10 chiffres) : coller l'indicatif sans retirer le 0.
  if (digits.length <= 10 && !digits.startsWith('225')) {
    digits = '225$digits';
  }

  return digits;
}

String _buildInvitationMessage({
  required Guest guest,
  WeddingSettings? settings,
}) {
  final bride = settings?.brideName ?? '';
  final groom = settings?.groomName ?? '';
  final title = settings?.title ?? 'Notre mariage';
  final date = settings?.eventDate;
  final rsvpDeadline = settings?.rsvpDeadline;

  final inviteUrl = invitationLinkForGuest(guest);

  final buffer = StringBuffer();

  // En-tête « Wedding » suivi des deux mariés (marié en premier), comme
  // demandé ; retombe sur le titre de l'espace si un nom manque.
  if (bride.isNotEmpty && groom.isNotEmpty) {
    buffer.writeln('💍 *Wedding $groom ET $bride*');
  } else {
    buffer.writeln('💍 *$title*');
  }
  buffer.writeln();

  // Personal greeting
  buffer.writeln('Cher(e) *${guest.fullName}*,');
  buffer.writeln();
  buffer.writeln("Nous avons l'honneur de vous inviter à notre mariage. 🎉");
  buffer.writeln();

  // Premier contact volontairement léger : la date seule (si renseignée),
  // sans lieu ni table — la place est communiquée après confirmation.
  if (date != null) {
    buffer.writeln('📅 Le *${_formatFrDate(date)}*');
    buffer.writeln();
  }

  // Délai laissé à l'invité pour répondre et confirmer sa présence.
  if (rsvpDeadline != null) {
    buffer.writeln(
      '📩 Merci de nous confirmer votre présence (présent ou absent) '
      'avant le *${_formatFrDate(rsvpDeadline)}* :',
    );
  } else {
    buffer.writeln(
      '📩 Merci de nous confirmer votre présence (présent ou absent) :',
    );
  }

  buffer.writeln();
  buffer.writeln('🔗 *Votre invitation :*');
  buffer.writeln(inviteUrl);
  buffer.writeln();

  // La table et la place ne sont attribuées qu'après confirmation.
  buffer.writeln(
    'Votre table et votre place vous seront communiquées après '
    'confirmation de votre présence.',
  );
  buffer.writeln();

  // Closing
  buffer.writeln('Au plaisir de célébrer avec vous ! 🥂');

  return buffer.toString();
}

/// Formate une date en français, ex. « 12 septembre 2026 ».
String _formatFrDate(DateTime date) {
  const months = [
    '',
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}
