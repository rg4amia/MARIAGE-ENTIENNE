import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  SubscriptionRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Forfait courant et consommation du mariage actif.
  ///
  /// Renvoie `null` tant que l'utilisateur n'a pas d'organisation : le
  /// parcours d'onboarding passe ici avant que l'espace n'existe.
  Future<SubscriptionOverview?> getOverview() async {
    final response = await _client.rpc('get_subscription_overview');
    if (response == null) return null;
    return SubscriptionOverview.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  /// Catalogue commercial, dans l'ordre d'affichage voulu.
  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _client
        .from('subscription_plans')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((row) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
