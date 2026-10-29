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

// ── Détails de la cérémonie ──────────────────────────────────────────────
// Lieux et horaires paramétrables dans les réglages (wedding_events). Ces
// valeurs ne servent de repli que tant que rien n'a été renseigné.
const String _ceremonyVenue = 'Quasi-Paroisse Sacré-Cœur d\'Akandjé';
const String _ceremonyTime = '15:00';
const String _receptionVenue = 'Espace JML Jouse';
const String _receptionTime = '19:00';

/// « 15:00 » → « 15 heures », « 15:30 » → « 15 h 30 ».
String formatEventTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]);
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  if (h == null) return hhmm;
  return m == 0
      ? '$h ${h > 1 ? 'heures' : 'heure'}'
      : '$h h ${m.toString().padLeft(2, '0')}';
}

// Replis sur les dates annoncées de l'invitation si elles ne sont pas
// renseignées dans l'application.
final DateTime _fallbackCeremonyDate = DateTime(2026, 11, 14);
final DateTime _fallbackRsvpDeadline = DateTime(2026, 11, 5);

// Repli si aucun nom de marié n'est enregistré dans l'espace.
const String _fallbackCouple = 'Kodjo & Marie Ange';

String _buildInvitationMessage({
  required Guest guest,
  WeddingSettings? settings,
}) {
  final bride = settings?.brideName ?? '';
  final groom = settings?.groomName ?? '';
  final title = settings?.title ?? 'Notre mariage';
  final ceremonyDate = settings?.eventDate ?? _fallbackCeremonyDate;
  final rsvpDeadline = settings?.rsvpDeadline ?? _fallbackRsvpDeadline;
  String pick(String? v, String fallback) =>
      (v == null || v.trim().isEmpty) ? fallback : v.trim();
  final ceremonyVenue = pick(settings?.ceremonyVenue, _ceremonyVenue);
  final ceremonyTime = formatEventTime(
    pick(settings?.ceremonyTime, _ceremonyTime),
  );
  final receptionVenue = pick(settings?.receptionVenue, _receptionVenue);
  final receptionTime = formatEventTime(
    pick(settings?.receptionTime, _receptionTime),
  );

  // Couple affiché dans le corps et la signature : noms des mariés tels que
  // renseignés dans les réglages, avec repli sur le couple de l'invitation.
  final couple = (bride.isNotEmpty && groom.isNotEmpty)
      ? '$groom & $bride'
      : _fallbackCouple;

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

  // Versets de l'invitation.
  buffer.writeln('Pour l\'époux');
  buffer.writeln(
    '« Maris, aimez vos femmes comme le Christ a aimé l\'Église et '
    's\'est livré lui-même pour elle. »',
  );
  buffer.writeln('— Éphésiens 5, 25');
  buffer.writeln();
  buffer.writeln('Pour l\'épouse');
  buffer.writeln('« Je suis à mon bien-aimé, et mon bien-aimé est à moi. »');
  buffer.writeln('— Cantique des Cantiques 6, 3');
  buffer.writeln();

  // Formule personnelle à l'invité.
  buffer.writeln('Cher(e) *${guest.fullName}*,');
  buffer.writeln();

  // Cérémonie religieuse.
  buffer.writeln(
    'C\'est avec une immense joie que *$couple* vous convient à la '
    'célébration de leur mariage religieux, le '
    '*${_formatFrWeekDate(ceremonyDate)}* à *$ceremonyTime*, '
    'à la *$ceremonyVenue*.',
  );
  buffer.writeln();

  // Réception.
  buffer.writeln(
    'La cérémonie sera suivie d\'une réception à *$receptionTime* '
    'à l\'*$receptionVenue*, pour célébrer ensemble l\'amour, la joie '
    'et cette précieuse alliance.',
  );
  buffer.writeln();

  // Délai laissé à l'invité pour confirmer sa présence.
  buffer.writeln(
    '📩 *RSVP — Confirmation de présence souhaitée au plus tard le '
    '${_formatFrOrdinalDate(rsvpDeadline)}.*',
  );
  buffer.writeln();

  buffer.writeln('🔗 *Votre invitation :*');
  buffer.writeln(inviteUrl);
  buffer.writeln();

  buffer.writeln(
    'Votre présence à nos côtés sera un honneur et une bénédiction '
    'pour notre foyer.',
  );
  buffer.writeln();
  buffer.writeln('Avec amour et gratitude,');
  buffer.write('$couple 🥂');

  return buffer.toString();
}

const List<String> _frMonths = [
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

const List<String> _frWeekdays = [
  '',
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Formate une date en français, ex. « 12 septembre 2026 ».
String _formatFrDate(DateTime date) {
  return '${date.day} ${_frMonths[date.month]} ${date.year}';
}

/// Date complète avec jour de la semaine, ex. « samedi 14 novembre 2026 ».
String _formatFrWeekDate(DateTime date) {
  return '${_frWeekdays[date.weekday]} ${_formatFrDate(date)}';
}

/// Date avec « 1er » pour le premier jour du mois,
/// ex. « 1er novembre 2026 ».
String _formatFrOrdinalDate(DateTime date) {
  final day = date.day == 1 ? '1er' : '${date.day}';
  return '$day ${_frMonths[date.month]} ${date.year}';
}
