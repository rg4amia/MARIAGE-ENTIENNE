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
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched;
  } catch (e) {
    debugPrint('Erreur ouverture WhatsApp: $e');
    // Fallback: try with wa:// scheme (some older WhatsApp versions)
    try {
      final fallback = Uri.parse('wa://send?phone=$phone&text=${Uri.encodeComponent(message)}');
      return await launchUrl(fallback, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Normalizes an Ivory Coast phone number to the format WhatsApp expects
/// (digits only, starting with country code, no '+' or spaces).
String _normalizePhone(String raw) {
  // Remove all non-digit characters
  var digits = raw.replaceAll(RegExp(r'[^\d]'), '');

  // Ivory Coast: +225 → strip leading 00 if present
  if (digits.startsWith('00225')) {
    digits = digits.substring(2); // → 225...
  }

  // Already starts with 225 but no leading +
  // If it starts with 0 after 225, remove the 0
  // e.g. 2250700000000 → already correct

  // If local number without country code (starts with 0 and ≤10 digits)
  if (digits.length <= 10 && digits.startsWith('0')) {
    digits = '225${digits.substring(1)}';
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
  final location = settings?.location ?? '';

  final portalUrl = SupabaseConfig.guestPortalUrl;
  final inviteUrl = '$portalUrl?token=${guest.qrToken}';

  final buffer = StringBuffer();

  // Opening with couple names
  if (bride.isNotEmpty && groom.isNotEmpty) {
    buffer.writeln('💍 *$bride & $groom*');
  } else {
    buffer.writeln('💍 *$title*');
  }
  buffer.writeln();

  // Personal greeting
  buffer.writeln('Cher(e) *${guest.fullName}*,');
  buffer.writeln();
  buffer.writeln(
    'Nous avons le plaisir de vous inviter à célébrer notre mariage ! 🎉',
  );
  buffer.writeln();

  // Event details
  if (date != null) {
    final months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    final day = date.day;
    final month = months[date.month];
    final year = date.year;
    buffer.writeln('📅 *Le $day $month $year*');
  }

  if (location.isNotEmpty) {
    buffer.writeln('📍 *$location*');
  }

  buffer.writeln();

  // Invitation link
  buffer.writeln('📲 Consultez votre carte d\'invitation ici :');
  buffer.writeln(inviteUrl);
  buffer.writeln();

  // Closing
  buffer.writeln('Au plaisir de célébrer avec vous ! 🥂');

  return buffer.toString();
}
