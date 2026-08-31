-- Fix: duplicate key on organization_subscriptions dans create_saas_workspace
--
-- Le trigger trg_organizations_default_subscription (20260831140000) s'exécute
-- immédiatement après l'INSERT sur organizations et crée déjà l'abonnement.
-- create_saas_workspace tentait ensuite un second INSERT sans ON CONFLICT,
-- provoquant une violation de contrainte unique.
-- Solution : ON CONFLICT (organization_id) DO UPDATE pour s'assurer que le
-- bon plan et le bon statut sont bien positionnés même si le trigger a déjà
-- inséré un abonnement par défaut.

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
SET search_path = public, extensions
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

  -- Le trigger trg_organizations_default_subscription a peut-être déjà inséré
  -- un abonnement par défaut. On s'assure que le plan et le statut sont corrects.
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
  )
  ON CONFLICT (organization_id) DO UPDATE
    SET plan_id          = excluded.plan_id,
        status           = excluded.status,
        trial_ends_at    = excluded.trial_ends_at,
        current_period_end = excluded.current_period_end;

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
