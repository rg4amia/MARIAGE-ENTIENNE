BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;

SELECT plan(6);

SELECT ok(
  (SELECT prosecdef
   FROM pg_proc
   WHERE oid = 'public.current_event_id()'::regprocedure),
  'current_event_id est SECURITY DEFINER'
);

SELECT ok(
  (SELECT proconfig @> ARRAY['search_path=public']
   FROM pg_proc
   WHERE oid = 'public.current_event_id()'::regprocedure),
  'current_event_id utilise un search_path fixe'
);

SELECT ok(
  has_function_privilege('authenticated', 'public.current_event_id()', 'EXECUTE'),
  'authenticated peut exécuter current_event_id'
);

SELECT ok(
  NOT has_function_privilege('anon', 'public.current_event_id()', 'EXECUTE'),
  'anon ne peut pas exécuter current_event_id'
);

INSERT INTO public.wedding_events (
  id,
  slug,
  title,
  bride_name,
  groom_name
) VALUES (
  '10000000-0000-0000-0000-000000000001',
  'rls-regression-test',
  'RLS regression test',
  'Test',
  'Test'
);

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '10000000-0000-0000-0000-000000000002',
  'authenticated',
  'authenticated',
  'rls-regression@example.test',
  crypt('not-used', gen_salt('bf')),
  now(),
  '{"role":"admin"}'::jsonb,
  '{"event_id":"10000000-0000-0000-0000-000000000001","full_name":"RLS Test"}'::jsonb,
  now(),
  now()
);

INSERT INTO public.profiles (id, event_id, full_name, role)
VALUES (
  '10000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000001',
  'RLS Test',
  'admin'
)
ON CONFLICT (id) DO UPDATE
SET event_id = EXCLUDED.event_id,
    full_name = EXCLUDED.full_name;

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated"}',
  true
);
SET LOCAL ROLE authenticated;

SELECT is(
  public.current_event_id(),
  '10000000-0000-0000-0000-000000000001'::uuid,
  'current_event_id retourne l événement du profil sans récursion RLS'
);

SELECT is(
  (SELECT count(*)::bigint
   FROM public.profiles
   WHERE id = '10000000-0000-0000-0000-000000000002'),
  1::bigint,
  'un utilisateur authentifié peut lire son propre profil sans récursion RLS'
);

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
