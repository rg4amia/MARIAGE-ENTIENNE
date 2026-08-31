import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Refus de quota renvoyé par la base : les déclencheurs SQL lèvent des
/// messages de la forme `QUOTA_INVITATIONS: Les 30 invitations ... `.
/// Le préfixe sert à les reconnaître, le reste est déjà rédigé pour l'écran.
class QuotaRefusal {
  /// `INVITATIONS`, `GUESTS`, `COLLABORATORS` ou `SUBSCRIPTION`.
  final String kind;

  /// Phrase en français à montrer telle quelle au couple.
  final String message;

  const QuotaRefusal({required this.kind, required this.message});

  /// Reconnaît un refus de quota dans n'importe quelle erreur remontée par
  /// Supabase. Renvoie `null` si l'erreur est d'une autre nature — auquel cas
  /// l'appelant doit la laisser remonter plutôt que de la maquiller.
  static QuotaRefusal? tryParse(Object? error) {
    if (error == null) return null;
    final raw = error is String ? error : error.toString();
    final match = RegExp(
      r'QUOTA_([A-Z_]+)\s*:\s*(.+?)(?:\r?\n|$)',
    ).firstMatch(raw);
    if (match == null) return null;
    return QuotaRefusal(
      kind: match.group(1)!,
      message: match.group(2)!.trim(),
    );
  }

  /// Le forfait est inactif : on invite à le réactiver, pas à en acheter un.
  bool get isSubscriptionLapsed => kind == 'SUBSCRIPTION';

  String get title =>
      isSubscriptionLapsed ? 'Forfait inactif' : 'Limite du forfait atteinte';

  String get actionLabel =>
      isSubscriptionLapsed ? 'Réactiver' : 'Voir les forfaits';
}

/// Exécute [action] et, si la base refuse pour cause de quota, propose le
/// changement de forfait au lieu de laisser passer une erreur technique.
/// Renvoie `true` quand l'action est réellement passée.
Future<bool> runWithQuotaGuard(Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (error) {
    final refusal = QuotaRefusal.tryParse(error);
    if (refusal == null) rethrow;
    await showQuotaDialog(refusal);
    return false;
  }
}

Future<void> showQuotaDialog(QuotaRefusal refusal) async {
  await Get.dialog<void>(
    AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(refusal.title, style: AppTextStyles.titleLg),
      content: Text(refusal.message, style: AppTextStyles.bodyMd),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text(
            'Plus tard',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.dark),
          ),
        ),
        FilledButton(
          onPressed: () {
            Get.back<void>();
            Get.toNamed(AppRoutes.plans);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(refusal.actionLabel),
        ),
      ],
    ),
  );
}
