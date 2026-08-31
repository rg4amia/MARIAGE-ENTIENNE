import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/data/models/subscription.dart';

Map<String, dynamic> planJson({
  String id = 'essentiel',
  String name = 'Essentiel',
  int amount = 0,
  String interval = 'one_time',
  String kind = 'wedding_pack',
  int maxEvents = 1,
  int maxGuests = -1,
  int maxInvitations = 30,
  int storageMb = 500,
  Map<String, dynamic> features = const {},
}) => {
  'id': id,
  'name': name,
  'description': null,
  'amount_xof': amount,
  'billing_interval': interval,
  'plan_kind': kind,
  'max_events': maxEvents,
  'max_guests_per_event': maxGuests,
  'max_invitations': maxInvitations,
  'max_storage_mb': storageMb,
  'features': features,
};

Map<String, dynamic> overviewJson({
  Map<String, dynamic>? plan,
  String status = 'active',
  String? trialEndsAt,
  int guests = 0,
  int invitationsSent = 0,
}) => {
  'status': status,
  'trial_ends_at': trialEndsAt,
  'current_period_end': null,
  'plan': plan ?? planJson(),
  'usage': {'events': 1, 'guests': guests, 'invitations_sent': invitationsSent},
};

void main() {
  group('SubscriptionPlan', () {
    test('formate un prix en francs avec séparateur de milliers', () {
      expect(
        SubscriptionPlan.fromJson(planJson(amount: 35000)).formattedAmount,
        '35 000 F',
      );
      expect(
        SubscriptionPlan.fromJson(planJson(amount: 550000)).formattedAmount,
        '550 000 F',
      );
      expect(SubscriptionPlan.fromJson(planJson()).formattedAmount, 'Gratuit');
    });

    test('distingue un pack mariage d’un abonnement récurrent', () {
      final pack = SubscriptionPlan.fromJson(planJson());
      final abonnement = SubscriptionPlan.fromJson(
        planJson(id: 'planner', kind: 'subscription', interval: 'month'),
      );

      expect(pack.isWeddingPack, isTrue);
      expect(pack.billingLabel, 'paiement unique');
      expect(abonnement.isWeddingPack, isFalse);
      expect(abonnement.billingLabel, 'par mois');
    });

    test('rend les quotas illimités lisibles', () {
      expect(SubscriptionPlan.quotaLabel(-1), 'Illimité');
      expect(SubscriptionPlan.quotaLabel(150), '150');
    });
  });

  group('SubscriptionOverview — quota d’invitations', () {
    test('décompte les invitations restantes', () {
      final overview = SubscriptionOverview.fromJson(
        overviewJson(invitationsSent: 12),
      );

      expect(overview.invitationsLeft, 18);
      expect(overview.invitationsRatio, closeTo(0.4, 0.001));
      expect(overview.shouldSuggestUpgrade, isFalse);
    });

    test('ne descend jamais sous zéro même si le quota est dépassé', () {
      final overview = SubscriptionOverview.fromJson(
        overviewJson(invitationsSent: 42),
      );

      expect(overview.invitationsLeft, 0);
      expect(overview.invitationsRatio, 1.0);
    });

    test('propose le pack supérieur avant le blocage, pas après', () {
      // 70 % du quota : le couple a encore de la marge, on l'avertit déjà.
      expect(
        SubscriptionOverview.fromJson(
          overviewJson(invitationsSent: 21),
        ).shouldSuggestUpgrade,
        isTrue,
      );
      expect(
        SubscriptionOverview.fromJson(
          overviewJson(invitationsSent: 20),
        ).shouldSuggestUpgrade,
        isFalse,
      );
    });

    test('un pack illimité n’affiche ni ratio ni relance', () {
      final overview = SubscriptionOverview.fromJson(
        overviewJson(
          plan: planJson(id: 'mariage_illimite', maxInvitations: -1),
          invitationsSent: 900,
        ),
      );

      expect(overview.invitationsLeft, SubscriptionPlan.unlimited);
      expect(overview.invitationsRatio, isNull);
      expect(overview.shouldSuggestUpgrade, isFalse);
    });
  });

  group('SubscriptionOverview — invités et statut', () {
    test('signale un nombre d’invités au-delà du pack', () {
      final overview = SubscriptionOverview.fromJson(
        overviewJson(
          plan: planJson(id: 'mariage_150', maxGuests: 150),
          guests: 168,
        ),
      );

      expect(overview.guestsExceedPlan, isTrue);
      expect(overview.shouldSuggestUpgrade, isTrue);
    });

    test('un pack sans limite d’invités ne déclenche pas d’alerte', () {
      final overview = SubscriptionOverview.fromJson(overviewJson(guests: 400));

      expect(overview.guestsExceedPlan, isFalse);
    });

    test('un abonnement impayé ou suspendu bloque et relance', () {
      for (final status in ['past_due', 'canceled', 'suspended']) {
        final overview = SubscriptionOverview.fromJson(
          overviewJson(status: status),
        );
        expect(overview.isBlocked, isTrue, reason: status);
        expect(overview.shouldSuggestUpgrade, isTrue, reason: status);
      }

      expect(
        SubscriptionOverview.fromJson(overviewJson(status: 'active')).isBlocked,
        isFalse,
      );
    });

    test('compte les jours d’essai restants', () {
      final endsAt = DateTime.now().add(const Duration(days: 5, hours: 2));
      final overview = SubscriptionOverview.fromJson(
        overviewJson(
          status: 'trialing',
          trialEndsAt: endsAt.toUtc().toIso8601String(),
        ),
      );

      expect(overview.isTrialing, isTrue);
      expect(overview.trialDaysLeft, 5);
    });

    test('sans essai, aucun décompte', () {
      expect(
        SubscriptionOverview.fromJson(overviewJson()).trialDaysLeft,
        isNull,
      );
    });
  });
}
