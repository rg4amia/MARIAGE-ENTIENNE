BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(31);

SELECT has_table('public', 'organizations', 'organizations existe');
SELECT has_table('public', 'organization_memberships', 'memberships existe');
SELECT has_table('public', 'subscription_plans', 'plans existe');
SELECT has_table('public', 'organization_subscriptions', 'subscriptions existe');
SELECT has_table('public', 'event_venues', 'event_venues existe');
SELECT has_table('public', 'invitation_templates', 'invitation_templates existe');
SELECT has_table('public', 'invitation_deliveries', 'invitation_deliveries existe');

SELECT has_column(
  'public', 'wedding_events', 'organization_id',
  'wedding_events porte la frontière organization_id'
);
SELECT col_not_null(
  'public', 'wedding_events', 'organization_id',
  'organization_id est obligatoire'
);
SELECT has_column(
  'public', 'profiles', 'active_event_id',
  'profiles permet de sélectionner le mariage actif'
);
SELECT has_column(
  'public', 'event_venues', 'latitude',
  'un lieu peut être géolocalisé'
);
SELECT has_column(
  'public', 'event_venues', 'maps_url',
  'un lieu conserve son URL Maps'
);
SELECT has_column(
  'public', 'seating_tables', 'venue_id',
  'une table appartient à un lieu de réception'
);
SELECT has_column(
  'public', 'chairs', 'is_accessible',
  'une chaise peut porter un besoin accessibilité'
);
SELECT has_trigger(
  'public', 'organization_memberships', 'trg_protect_last_organization_owner',
  'une organisation conserve toujours un propriétaire actif'
);
SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_guest_event_fkey'
      AND convalidated
  ),
  'une invitation ne peut pas référencer un invité d’un autre mariage'
);

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.organizations'::regclass),
  'RLS active sur organizations'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.event_venues'::regclass),
  'RLS active sur event_venues'
);
SELECT has_function(
  'public', 'create_saas_workspace',
  ARRAY['text', 'text', 'text', 'text', 'timestamp with time zone', 'character varying', 'text'],
  'RPC onboarding SaaS disponible'
);
SELECT has_function(
  'public', 'switch_active_event', ARRAY['uuid'],
  'RPC de changement de mariage disponible'
);
SELECT ok(
  (
    SELECT prosecdef
    FROM pg_proc
    WHERE oid = 'public.create_saas_workspace(text,text,text,text,timestamptz,character varying,text)'::regprocedure
  ),
  'onboarding exécuté en SECURITY DEFINER'
);
SELECT ok(
  (
    SELECT proconfig @> ARRAY['search_path=public']
    FROM pg_proc
    WHERE oid = 'public.create_saas_workspace(text,text,text,text,timestamptz,character varying,text)'::regprocedure
  ),
  'onboarding fixe search_path'
);

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '20000000-0000-0000-0000-000000000001',
  'authenticated', 'authenticated', 'owner-saas@example.test',
  crypt('not-used', gen_salt('bf')), now(),
  '{}'::jsonb,
  '{"full_name":"Aïcha Organisatrice","phone":"+2250100000000"}'::jsonb,
  now(), now()
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}',
  true
);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$
    SELECT public.create_saas_workspace(
      'Agence Aïcha',
      'Mariage Aïcha et Karim',
      'Aïcha',
      'Karim',
      '2027-08-14 14:00:00+00'::timestamptz,
      'CI',
      'Africa/Abidjan'
    )
  $$,
  'un utilisateur authentifié crée son workspace et son mariage'
);

SELECT is(
  (SELECT count(*)::bigint FROM public.organizations),
  1::bigint,
  'le propriétaire voit son organisation'
);
SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.organization_memberships
    WHERE user_id = auth.uid() AND role = 'owner' AND status = 'active'
  ),
  1::bigint,
  'le créateur devient propriétaire actif'
);
SELECT is(
  (SELECT count(*)::bigint FROM public.event_venues),
  3::bigint,
  'Mairie, Église et Salle de réception sont préparées'
);
SELECT is(
  (SELECT count(*)::bigint FROM public.invitation_templates WHERE is_default),
  1::bigint,
  'une carte Celestial Romance est créée par défaut'
);
SELECT is(
  (
    SELECT count(*)::bigint
    FROM public.organization_subscriptions
    WHERE plan_id = 'pro' AND status = 'trialing'
  ),
  1::bigint,
  'le workspace bénéficie de essai Pro'
);
SELECT is(
  public.switch_active_event(public.current_event_id()),
  public.current_event_id(),
  'le propriétaire peut activer un mariage autorisé'
);

RESET ROLE;

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '20000000-0000-0000-0000-000000000002',
  'authenticated', 'authenticated', 'outsider-saas@example.test',
  crypt('not-used', gen_salt('bf')), now(),
  '{}'::jsonb,
  '{"full_name":"Utilisateur Externe"}'::jsonb,
  now(), now()
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
SET LOCAL ROLE authenticated;

SELECT is(
  (SELECT count(*)::bigint FROM public.organizations),
  0::bigint,
  'un autre compte ne voit aucune organisation étrangère'
);
SELECT is(
  (SELECT count(*)::bigint FROM public.event_venues),
  0::bigint,
  'un autre compte ne voit aucun lieu étranger'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
