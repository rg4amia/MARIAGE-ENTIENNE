/// Forfait commercial : un pack mariage payé une fois, ou un abonnement
/// récurrent pour les wedding planners.
class SubscriptionPlan {
  /// Valeur des quotas sans limite, côté base comme côté `features`.
  static const unlimited = -1;

  final String id;
  final String name;
  final String? description;
  final int amountXof;
  final String billingInterval;
  final String planKind;
  final int maxEvents;
  final int maxGuestsPerEvent;
  final int maxInvitations;
  final int maxStorageMb;
  final Map<String, dynamic> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.amountXof,
    required this.billingInterval,
    required this.planKind,
    required this.maxEvents,
    required this.maxGuestsPerEvent,
    required this.maxInvitations,
    required this.maxStorageMb,
    this.features = const {},
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      amountXof: (json['amount_xof'] as num?)?.toInt() ?? 0,
      billingInterval: json['billing_interval'] as String? ?? 'one_time',
      planKind: json['plan_kind'] as String? ?? 'subscription',
      maxEvents: (json['max_events'] as num?)?.toInt() ?? unlimited,
      maxGuestsPerEvent:
          (json['max_guests_per_event'] as num?)?.toInt() ?? unlimited,
      maxInvitations: (json['max_invitations'] as num?)?.toInt() ?? unlimited,
      maxStorageMb: (json['max_storage_mb'] as num?)?.toInt() ?? 0,
      features: Map<String, dynamic>.from(
        json['features'] as Map? ?? const {},
      ),
    );
  }

  bool get isFree => amountXof == 0;

  /// Un pack se paie une fois pour un mariage, un abonnement se renouvelle.
  bool get isWeddingPack => planKind == 'wedding_pack';

  bool get hasWatermark => features['watermark'] == true;
  bool get hasPrioritySupport => features['priority_support'] == true;
  bool get hasHdExport => features['hd_export'] == true;

  int get collaborators =>
      (features['collaborators'] as num?)?.toInt() ?? unlimited;

  /// « 35 000 F » plutôt que « 35000 » : le séparateur de milliers est ce qui
  /// rend un prix lisible d'un coup d'œil.
  String get formattedAmount {
    if (isFree) return 'Gratuit';
    final digits = amountXof.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return '$buffer F';
  }

  String get billingLabel => switch (billingInterval) {
    'month' => 'par mois',
    'year' => 'par an',
    _ => 'paiement unique',
  };

  /// Libellé d'un quota, `-1` valant « illimité ».
  static String quotaLabel(int value) =>
      value == unlimited ? 'Illimité' : '$value';
}

/// Consommation réelle du mariage actif, renvoyée avec le forfait.
class SubscriptionUsage {
  final int events;
  final int guests;
  final int invitationsSent;

  const SubscriptionUsage({
    this.events = 0,
    this.guests = 0,
    this.invitationsSent = 0,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) {
    return SubscriptionUsage(
      events: (json['events'] as num?)?.toInt() ?? 0,
      guests: (json['guests'] as num?)?.toInt() ?? 0,
      invitationsSent: (json['invitations_sent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// État complet du forfait de l'organisation : ce que l'app doit connaître
/// pour prévenir avant de bloquer.
class SubscriptionOverview {
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final SubscriptionPlan plan;
  final SubscriptionUsage usage;

  const SubscriptionOverview({
    required this.status,
    this.trialEndsAt,
    this.currentPeriodEnd,
    required this.plan,
    required this.usage,
  });

  factory SubscriptionOverview.fromJson(Map<String, dynamic> json) {
    return SubscriptionOverview(
      status: json['status'] as String? ?? 'active',
      trialEndsAt: _parseDate(json['trial_ends_at']),
      currentPeriodEnd: _parseDate(json['current_period_end']),
      plan: SubscriptionPlan.fromJson(
        Map<String, dynamic>.from(json['plan'] as Map),
      ),
      usage: SubscriptionUsage.fromJson(
        Map<String, dynamic>.from(json['usage'] as Map? ?? const {}),
      ),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value as String)?.toLocal();

  bool get isTrialing => status == 'trialing';

  /// `past_due`, `canceled` et `suspended` coupent l'accès aux envois.
  bool get isBlocked =>
      status == 'past_due' || status == 'canceled' || status == 'suspended';

  int? get trialDaysLeft {
    final endsAt = trialEndsAt;
    if (endsAt == null) return null;
    return endsAt.difference(DateTime.now()).inDays;
  }

  int get invitationsLeft {
    if (plan.maxInvitations == SubscriptionPlan.unlimited) {
      return SubscriptionPlan.unlimited;
    }
    final left = plan.maxInvitations - usage.invitationsSent;
    return left < 0 ? 0 : left;
  }

  /// Progression du quota d'invitations, `null` si le pack est illimité.
  double? get invitationsRatio {
    if (plan.maxInvitations == SubscriptionPlan.unlimited ||
        plan.maxInvitations == 0) {
      return null;
    }
    final ratio = usage.invitationsSent / plan.maxInvitations;
    return ratio.clamp(0.0, 1.0);
  }

  bool get guestsExceedPlan =>
      plan.maxGuestsPerEvent != SubscriptionPlan.unlimited &&
      usage.guests > plan.maxGuestsPerEvent;

  /// Vrai quand il reste peu d'invitations : c'est le moment où l'on propose
  /// le pack supérieur, avant que le couple ne se retrouve bloqué.
  bool get shouldSuggestUpgrade {
    if (isBlocked) return true;
    if (guestsExceedPlan) return true;
    final ratio = invitationsRatio;
    return ratio != null && ratio >= 0.7;
  }
}
