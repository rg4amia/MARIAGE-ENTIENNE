-- ============================================================
-- Packs mariage (paiement unique) et abonnements professionnels
--
-- Un mariage n'est pas un abonnement : le couple prépare pendant
-- quelques mois, se marie une fois et s'en va. Le facturer au mois le
-- pousse à tout tasser dans l'essai puis à résilier. Les couples
-- passent donc sur des packs à paiement unique dimensionnés par
-- volume d'invités, tandis que les wedding planners — qui ont un flux
-- continu de mariages — gardent un abonnement récurrent.
-- ============================================================

-- ============================================================
-- 1. STRUCTURE : DEUX FAMILLES DE FORFAITS
-- ============================================================

ALTER TABLE public.subscription_plans
  ADD COLUMN IF NOT EXISTS plan_kind text NOT NULL DEFAULT 'subscription',
  ADD COLUMN IF NOT EXISTS max_invitations integer NOT NULL DEFAULT -1;

COMMENT ON COLUMN public.subscription_plans.plan_kind IS
  'wedding_pack = achat unique pour un mariage, subscription = abonnement pro';
COMMENT ON COLUMN public.subscription_plans.max_invitations IS
  'Invitations envoyables ; -1 = illimité. C''est le quota qui déclenche la vente.';

-- Les quotas illimités se notent -1, comme le faisait déjà `features`.
-- Les CHECK en ligne d'origine portent les noms auto-générés par Postgres.
ALTER TABLE public.subscription_plans
  DROP CONSTRAINT IF EXISTS subscription_plans_billing_interval_check,
  DROP CONSTRAINT IF EXISTS subscription_plans_max_guests_per_event_check,
  DROP CONSTRAINT IF EXISTS subscription_plans_max_events_check,
  DROP CONSTRAINT IF EXISTS subscription_plans_plan_kind_check,
  DROP CONSTRAINT IF EXISTS subscription_plans_max_invitations_check;

ALTER TABLE public.subscription_plans
  ADD CONSTRAINT subscription_plans_billing_interval_check
    CHECK (billing_interval IN ('month', 'year', 'one_time')),
  ADD CONSTRAINT subscription_plans_max_guests_per_event_check
    CHECK (max_guests_per_event = -1 OR max_guests_per_event > 0),
  ADD CONSTRAINT subscription_plans_max_events_check
    CHECK (max_events = -1 OR max_events > 0),
  ADD CONSTRAINT subscription_plans_max_invitations_check
    CHECK (max_invitations = -1 OR max_invitations >= 0),
  ADD CONSTRAINT subscription_plans_plan_kind_check
    CHECK (plan_kind IN ('wedding_pack', 'subscription'));

-- ============================================================
-- 2. CATALOGUE COMMERCIAL
-- ============================================================

INSERT INTO public.subscription_plans (
  id, name, description, amount_xof, billing_interval, trial_days,
  plan_kind, max_events, max_guests_per_event, max_invitations,
  max_storage_mb, features, sort_order
) VALUES
  -- ── Packs mariage : le couple paie une fois, pour son mariage ──
  (
    'essentiel', 'Essentiel',
    'Préparez tout votre mariage gratuitement',
    0, 'one_time', 0, 'wedding_pack',
    1, -1, 30, 500,
    '{"invitation_templates": 1, "collaborators": 1, "custom_branding": true,
      "watermark": true, "priority_support": false, "hd_export": false}'::jsonb,
    10
  ),
  (
    'mariage_150', 'Mariage 150',
    'Jusqu''à 150 invités, sans filigrane',
    35000, 'one_time', 0, 'wedding_pack',
    1, 150, 150, 5120,
    '{"invitation_templates": -1, "collaborators": 1, "custom_branding": true,
      "watermark": false, "priority_support": false, "hd_export": false}'::jsonb,
    20
  ),
  (
    'mariage_300', 'Mariage 300',
    'Jusqu''à 300 invités, témoins et coordinateurs inclus',
    60000, 'one_time', 0, 'wedding_pack',
    1, 300, 300, 10240,
    '{"invitation_templates": -1, "collaborators": 3, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": false}'::jsonb,
    30
  ),
  (
    'mariage_illimite', 'Mariage Illimité',
    'Aucune limite d''invités, album vidéo en qualité HD',
    95000, 'one_time', 0, 'wedding_pack',
    1, -1, -1, 20480,
    '{"invitation_templates": -1, "collaborators": 6, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": true}'::jsonb,
    40
  ),
  -- ── Abonnements : le professionnel a un flux continu de mariages ──
  (
    'planner', 'Planner',
    'Pour le wedding planner indépendant',
    20000, 'month', 14, 'subscription',
    5, 300, -1, 20480,
    '{"invitation_templates": -1, "collaborators": 5, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": false,
      "agency_branding": true}'::jsonb,
    50
  ),
  (
    'planner_annuel', 'Planner (annuel)',
    'Deux mois offerts sur l''abonnement Planner',
    200000, 'year', 14, 'subscription',
    5, 300, -1, 20480,
    '{"invitation_templates": -1, "collaborators": 5, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": false,
      "agency_branding": true}'::jsonb,
    60
  ),
  (
    'agence', 'Agence',
    'Pour gérer plusieurs mariages en parallèle',
    55000, 'month', 14, 'subscription',
    25, -1, -1, 51200,
    '{"invitation_templates": -1, "collaborators": 25, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": true,
      "agency_branding": true}'::jsonb,
    70
  ),
  (
    'agence_annuel', 'Agence (annuel)',
    'Deux mois offerts sur l''abonnement Agence',
    550000, 'year', 14, 'subscription',
    25, -1, -1, 51200,
    '{"invitation_templates": -1, "collaborators": 25, "custom_branding": true,
      "watermark": false, "priority_support": true, "hd_export": true,
      "agency_branding": true}'::jsonb,
    80
  )
ON CONFLICT (id) DO UPDATE SET
  name = excluded.name,
  description = excluded.description,
  amount_xof = excluded.amount_xof,
  billing_interval = excluded.billing_interval,
  trial_days = excluded.trial_days,
  plan_kind = excluded.plan_kind,
  max_events = excluded.max_events,
  max_guests_per_event = excluded.max_guests_per_event,
  max_invitations = excluded.max_invitations,
  max_storage_mb = excluded.max_storage_mb,
  features = excluded.features,
  sort_order = excluded.sort_order,
  is_active = true;

-- ============================================================
-- 3. RETRAIT DE L'ANCIENNE GRILLE
--
-- `plan_id` est en ON DELETE RESTRICT : on désactive au lieu de
-- supprimer, puis on bascule les abonnements existants vers le
-- forfait équivalent. Personne n'ayant encore payé, les couples
-- repartent sur le pack gratuit plutôt que sur un essai qui expire.
-- ============================================================

UPDATE public.subscription_plans
SET is_active = false
WHERE id IN ('discovery', 'pro', 'agency');

UPDATE public.organization_subscriptions
SET plan_id = 'essentiel',
    status = 'active'::public.subscription_status,
    trial_ends_at = NULL,
    current_period_end = NULL
WHERE plan_id IN ('discovery', 'pro');

UPDATE public.organization_subscriptions
SET plan_id = 'agence'
WHERE plan_id = 'agency';

-- ============================================================
-- 4. NOUVEAU FORFAIT PAR DÉFAUT À L'INSCRIPTION
--
-- L'ancienne version plaçait tout le monde en essai `pro` de 14 jours
-- sans jamais le dire ni le faire expirer. Le pack gratuit ne périme
-- pas : la conversion se joue au moment de l'envoi des invitations.
-- ============================================================

CREATE OR REPLACE FUNCTION public.default_signup_plan()
RETURNS public.subscription_plans
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT * FROM public.subscription_plans
  WHERE id = 'essentiel' AND is_active
  LIMIT 1;
$$;

-- ============================================================
-- 5. ÉTAT DU FORFAIT ET CONSOMMATION RÉELLE
--
-- SECURITY DEFINER : `subscriptions_manager_select` réserve la lecture
-- aux owner/admin, or un coordinateur doit aussi comprendre pourquoi
-- un envoi est bloqué.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_subscription_overview()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_organization_id uuid := public.current_organization_id();
  v_event_id        uuid := public.current_event_id();
  v_subscription    public.organization_subscriptions;
  v_plan            public.subscription_plans;
  v_guests          integer := 0;
  v_invitations     integer := 0;
  v_events          integer := 0;
BEGIN
  IF v_organization_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_subscription
  FROM public.organization_subscriptions
  WHERE organization_id = v_organization_id;

  IF v_subscription.id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = v_subscription.plan_id;

  SELECT count(*) INTO v_events
  FROM public.wedding_events
  WHERE organization_id = v_organization_id
    AND status <> 'archived';

  IF v_event_id IS NOT NULL THEN
    SELECT count(*) INTO v_guests
    FROM public.guests
    WHERE event_id = v_event_id;

    -- Une invitation renvoyée ne consomme pas deux fois le quota.
    SELECT count(DISTINCT invitation_id) INTO v_invitations
    FROM public.invitation_deliveries
    WHERE event_id = v_event_id
      AND status IN ('sent', 'delivered', 'opened');
  END IF;

  RETURN jsonb_build_object(
    'status', v_subscription.status,
    'trial_ends_at', v_subscription.trial_ends_at,
    'current_period_end', v_subscription.current_period_end,
    'plan', jsonb_build_object(
      'id', v_plan.id,
      'name', v_plan.name,
      'description', v_plan.description,
      'amount_xof', v_plan.amount_xof,
      'billing_interval', v_plan.billing_interval,
      'plan_kind', v_plan.plan_kind,
      'max_events', v_plan.max_events,
      'max_guests_per_event', v_plan.max_guests_per_event,
      'max_invitations', v_plan.max_invitations,
      'max_storage_mb', v_plan.max_storage_mb,
      'features', v_plan.features
    ),
    'usage', jsonb_build_object(
      'events', v_events,
      'guests', v_guests,
      'invitations_sent', v_invitations
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_subscription_overview() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_subscription_overview() TO authenticated;
REVOKE ALL ON FUNCTION public.default_signup_plan() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.default_signup_plan() TO authenticated;

-- ============================================================
-- 6. INSCRIPTION SUR LE PACK GRATUIT
--
-- Reprise de `create_saas_workspace` : seul le forfait attribué
-- change, le reste de la création d'espace est inchangé.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_saas_workspace(
  p_organization_name text,
  p_event_title text,
  p_bride_name text,
  p_groom_name text,
  p_event_date timestamptz DEFAULT NULL,
  p_country_code varchar(2) DEFAULT 'CI',
  p_timezone text DEFAULT 'Africa/Abidjan'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_organization public.organizations;
  v_event public.wedding_events;
  v_plan public.subscription_plans;
  v_base_slug text;
  v_full_name text;
  v_phone text;
  v_trial_ends_at timestamptz;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.organization_memberships
    WHERE user_id = v_user_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'The current user already belongs to an organization';
  END IF;
  IF nullif(btrim(p_organization_name), '') IS NULL THEN
    RAISE EXCEPTION 'Organization name is required';
  END IF;
  IF nullif(btrim(p_event_title), '') IS NULL
     OR nullif(btrim(p_bride_name), '') IS NULL
     OR nullif(btrim(p_groom_name), '') IS NULL THEN
    RAISE EXCEPTION 'Wedding title and couple names are required';
  END IF;

  SELECT * INTO v_plan FROM public.default_signup_plan();
  IF v_plan.id IS NULL THEN
    RAISE EXCEPTION 'Default SaaS plan is unavailable';
  END IF;

  -- Un pack mariage ne périme pas : pas d'essai, pas de fin de période.
  v_trial_ends_at := CASE
    WHEN v_plan.trial_days > 0
      THEN timezone('utc', now()) + make_interval(days => v_plan.trial_days)
  END;

  v_base_slug := public.saas_slug(p_organization_name);
  IF v_base_slug = '' THEN v_base_slug := 'organisation'; END IF;

  SELECT
    coalesce(
      nullif(raw_user_meta_data ->> 'full_name', ''),
      split_part(email, '@', 1),
      'Organisateur'
    ),
    nullif(raw_user_meta_data ->> 'phone', '')
  INTO v_full_name, v_phone
  FROM auth.users
  WHERE id = v_user_id;

  INSERT INTO public.organizations (
    slug, name, country_code, currency_code, timezone
  ) VALUES (
    v_base_slug || '-' || encode(gen_random_bytes(3), 'hex'),
    btrim(p_organization_name),
    upper(coalesce(nullif(btrim(p_country_code), ''), 'CI')),
    'XOF',
    coalesce(nullif(btrim(p_timezone), ''), 'Africa/Abidjan')
  ) RETURNING * INTO v_organization;

  INSERT INTO public.organization_memberships (
    organization_id, user_id, role, status, accepted_at
  ) VALUES (
    v_organization.id,
    v_user_id,
    'owner',
    'active',
    timezone('utc', now())
  );

  INSERT INTO public.organization_subscriptions (
    organization_id, plan_id, status, trial_ends_at, current_period_end
  ) VALUES (
    v_organization.id,
    v_plan.id,
    CASE WHEN v_trial_ends_at IS NULL
      THEN 'active'::public.subscription_status
      ELSE 'trialing'::public.subscription_status
    END,
    v_trial_ends_at,
    v_trial_ends_at
  );

  INSERT INTO public.wedding_events (
    organization_id, slug, title, bride_name, groom_name,
    event_date, timezone, status
  ) VALUES (
    v_organization.id,
    public.saas_slug(p_event_title) || '-' || encode(gen_random_bytes(3), 'hex'),
    btrim(p_event_title),
    btrim(p_bride_name),
    btrim(p_groom_name),
    p_event_date,
    v_organization.timezone,
    'planning'
  ) RETURNING * INTO v_event;

  INSERT INTO public.profiles (
    id, event_id, active_event_id, role, full_name, phone
  ) VALUES (
    v_user_id, v_event.id, v_event.id, 'admin', v_full_name, v_phone
  )
  ON CONFLICT (id) DO UPDATE SET
    event_id = excluded.event_id,
    active_event_id = excluded.active_event_id,
    full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name),
    phone = coalesce(public.profiles.phone, excluded.phone),
    updated_at = timezone('utc', now());

  INSERT INTO public.event_venues (event_id, venue_type, name, sort_order)
  VALUES
    (v_event.id, 'town_hall', 'Mairie', 10),
    (v_event.id, 'church', 'Église', 20),
    (v_event.id, 'reception', 'Salle de réception', 30);

  INSERT INTO public.invitation_templates (
    event_id, name, template_key, is_default, palette, typography, content
  ) VALUES (
    v_event.id,
    'Celestial Romance',
    'celestial-romance',
    true,
    '{"primary":"#A53C00","secondary":"#9C4236","accent":"#BE9A7A","background":"#FFF8F4"}'::jsonb,
    '{"heading":"Libre Caslon Text","body":"Plus Jakarta Sans"}'::jsonb,
    '{"show_venues":true,"show_table":true,"show_chair":true,"show_qr":true}'::jsonb
  );

  RETURN jsonb_build_object(
    'organization_id', v_organization.id,
    'organization_name', v_organization.name,
    'event_id', v_event.id,
    'event_title', v_event.title,
    'plan_id', v_plan.id,
    'plan_name', v_plan.name,
    'trial_ends_at', v_trial_ends_at
  );
END;
$$;
