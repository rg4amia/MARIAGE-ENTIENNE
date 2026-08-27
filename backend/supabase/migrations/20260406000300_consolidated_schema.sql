-- ============================================================
-- Migration 003: Schéma consolidé — état final de production
-- ============================================================
-- Consolide les migrations 001–006 de supabase/migrations/ avec
-- le schéma de référence backend/supabase/migrations/000100.
--
-- Architecture finale :
--   - wedding_events   : événement de mariage central
--   - profiles         : admin lié à auth.users
--   - guests           : invités rattachés à un event
--   - seating_tables   : tables de placement
--   - chairs           : chaises par table
--   - invitations      : invitation générée par guest+chair
--   - guest_media_submissions : médias déposés par les invités
--   - guest_links      : codes courts QR → token invité
--
-- RLS : is_admin() lit le JWT (app_metadata.role = 'admin')
--       → aucune requête sur profiles → pas de récursion.
-- ============================================================


-- ============================================================
-- 1. EXTENSIONS
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
-- 2. TYPES ENUM
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
    CREATE TYPE public.app_role AS ENUM ('admin');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invitation_status') THEN
    CREATE TYPE public.invitation_status AS ENUM (
      'draft',
      'pending_media',
      'media_uploaded',
      'card_unlocked'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'guest_media_type') THEN
    CREATE TYPE public.guest_media_type AS ENUM ('audio', 'video');
  END IF;
END $$;


-- ============================================================
-- 3. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.wedding_events (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text        NOT NULL UNIQUE,
  title       text        NOT NULL,
  bride_name  text        NOT NULL,
  groom_name  text        NOT NULL,
  location    text,
  event_date  timestamptz,
  created_at  timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at  timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid            PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  event_id    uuid            NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  role        public.app_role NOT NULL DEFAULT 'admin',
  full_name   text            NOT NULL,
  phone       text,
  created_at  timestamptz     NOT NULL DEFAULT timezone('utc', now()),
  updated_at  timestamptz     NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.guests (
  id          uuid                       PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    uuid                       NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  full_name   text                       NOT NULL,
  phone       text,
  email       text,
  qr_token    text                       NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),
  status      public.invitation_status   NOT NULL DEFAULT 'draft',
  notes       text,
  created_at  timestamptz                NOT NULL DEFAULT timezone('utc', now()),
  updated_at  timestamptz                NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.seating_tables (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id    uuid        NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  label       text        NOT NULL,
  capacity    integer     NOT NULL CHECK (capacity > 0),
  created_at  timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at  timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (event_id, label)
);

CREATE TABLE IF NOT EXISTS public.chairs (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id      uuid        NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  table_id      uuid        NOT NULL REFERENCES public.seating_tables(id) ON DELETE CASCADE,
  chair_number  integer     NOT NULL CHECK (chair_number > 0),
  guest_id      uuid        UNIQUE REFERENCES public.guests(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at    timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (table_id, chair_number)
);

CREATE TABLE IF NOT EXISTS public.invitations (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id            uuid        NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  guest_id            uuid        NOT NULL UNIQUE REFERENCES public.guests(id) ON DELETE CASCADE,
  table_id            uuid        NOT NULL REFERENCES public.seating_tables(id) ON DELETE CASCADE,
  chair_id            uuid        NOT NULL REFERENCES public.chairs(id) ON DELETE CASCADE,
  invitation_code     text        NOT NULL UNIQUE,
  web_url             text        NOT NULL,
  deep_link           text        NOT NULL,
  qr_payload          text        NOT NULL,
  png_storage_path    text,
  pdf_storage_path    text,
  is_unlocked         boolean     NOT NULL DEFAULT false,
  unlocked_at         timestamptz,
  created_at          timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at          timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.guest_media_submissions (
  id                        uuid                     PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id                  uuid                     NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  guest_id                  uuid                     NOT NULL REFERENCES public.guests(id) ON DELETE CASCADE,
  invitation_id             uuid                     NOT NULL REFERENCES public.invitations(id) ON DELETE CASCADE,
  media_type                public.guest_media_type  NOT NULL,
  storage_path              text                     NOT NULL,
  mime_type                 text,
  file_size_bytes           bigint,
  client_duration_seconds   numeric(8,2)             NOT NULL,
  server_duration_seconds   numeric(8,2),
  client_validated          boolean                  NOT NULL DEFAULT false,
  server_validated          boolean                  NOT NULL DEFAULT false,
  validation_notes          text,
  submitted_at              timestamptz              NOT NULL DEFAULT timezone('utc', now()),
  created_at                timestamptz              NOT NULL DEFAULT timezone('utc', now())
);

-- Codes courts QR → token invité (pour les liens de partage)
CREATE TABLE IF NOT EXISTS public.guest_links (
  id              uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
  short_code      varchar(8)   NOT NULL UNIQUE,
  guest_token     text         NOT NULL,
  guest_id        uuid         NOT NULL REFERENCES public.guests(id) ON DELETE CASCADE,
  is_active       boolean      DEFAULT true,
  scan_count      integer      DEFAULT 0,
  last_scanned_at timestamptz,
  created_at      timestamptz  DEFAULT timezone('utc', now())
);


-- ============================================================
-- 4. INDEX
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_guests_qr_token              ON public.guests(qr_token);
CREATE INDEX IF NOT EXISTS idx_guests_event_id              ON public.guests(event_id);
CREATE INDEX IF NOT EXISTS idx_chairs_table_id              ON public.chairs(table_id);
CREATE INDEX IF NOT EXISTS idx_invitations_guest_id         ON public.invitations(guest_id);
CREATE INDEX IF NOT EXISTS idx_media_submissions_guest_id   ON public.guest_media_submissions(guest_id);
CREATE INDEX IF NOT EXISTS idx_media_submissions_invitation ON public.guest_media_submissions(invitation_id);
CREATE INDEX IF NOT EXISTS idx_guest_links_short_code       ON public.guest_links(short_code);
CREATE INDEX IF NOT EXISTS idx_guest_links_guest_id         ON public.guest_links(guest_id);


-- ============================================================
-- 5. TRIGGER updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_wedding_events_updated_at  ON public.wedding_events;
DROP TRIGGER IF EXISTS trg_profiles_updated_at        ON public.profiles;
DROP TRIGGER IF EXISTS trg_guests_updated_at          ON public.guests;
DROP TRIGGER IF EXISTS trg_tables_updated_at          ON public.seating_tables;
DROP TRIGGER IF EXISTS trg_chairs_updated_at          ON public.chairs;
DROP TRIGGER IF EXISTS trg_invitations_updated_at     ON public.invitations;

CREATE TRIGGER trg_wedding_events_updated_at
  BEFORE UPDATE ON public.wedding_events
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_guests_updated_at
  BEFORE UPDATE ON public.guests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_tables_updated_at
  BEFORE UPDATE ON public.seating_tables
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_chairs_updated_at
  BEFORE UPDATE ON public.chairs
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_invitations_updated_at
  BEFORE UPDATE ON public.invitations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- 6. FONCTION is_admin() — lit le JWT, pas la table profiles
--    SECURITY DEFINER + JWT → zéro récursion RLS
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(
    (SELECT auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
$$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.is_admin() TO authenticated;


-- ============================================================
-- 7. TRIGGER nouvel utilisateur → profil + JWT app_metadata
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Inscrire role=admin dans app_metadata (signé par Supabase, non modifiable par le client)
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  WHERE id = NEW.id;

  -- Créer le profil (event_id sera renseigné séparément par l'admin)
  -- On insère seulement si un event_id est fourni dans user_metadata
  INSERT INTO public.profiles (id, event_id, full_name, phone, role)
  SELECT
    NEW.id,
    (NEW.raw_user_meta_data ->> 'event_id')::uuid,
    coalesce(NEW.raw_user_meta_data ->> 'full_name', ''),
    NEW.raw_user_meta_data ->> 'phone',
    'admin'
  WHERE (NEW.raw_user_meta_data ->> 'event_id') IS NOT NULL
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_role();

-- Mettre à jour les utilisateurs existants (rétroactif)
UPDATE auth.users
SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
WHERE raw_app_meta_data ->> 'role' IS DISTINCT FROM 'admin';


-- ============================================================
-- 8. FONCTIONS MÉTIER
-- ============================================================

-- Retourne l'event_id de l'admin connecté
CREATE OR REPLACE FUNCTION public.current_event_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT event_id
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;
$$;

-- Assigne un invité à une chaise et génère/met à jour son invitation
CREATE OR REPLACE FUNCTION public.assign_guest_to_chair(
  p_guest_id           uuid,
  p_chair_id           uuid,
  p_public_base_url    text DEFAULT 'https://mariage-entienne.app',
  p_deep_link_base     text DEFAULT 'mariageentienne://guest'
)
RETURNS public.invitations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guest      public.guests;
  v_chair      public.chairs;
  v_table      public.seating_tables;
  v_token      text;
  v_invitation public.invitations;
BEGIN
  SELECT * INTO v_guest FROM public.guests WHERE id = p_guest_id;
  IF v_guest.id IS NULL THEN RAISE EXCEPTION 'Guest not found'; END IF;

  SELECT * INTO v_chair FROM public.chairs WHERE id = p_chair_id;
  IF v_chair.id IS NULL THEN RAISE EXCEPTION 'Chair not found'; END IF;

  IF v_chair.guest_id IS NOT NULL AND v_chair.guest_id <> p_guest_id THEN
    RAISE EXCEPTION 'Chair already assigned';
  END IF;

  -- Libérer l'ancienne chaise de cet invité
  UPDATE public.chairs SET guest_id = NULL WHERE guest_id = p_guest_id;

  -- Assigner la nouvelle chaise
  UPDATE public.chairs SET guest_id = p_guest_id WHERE id = p_chair_id;

  SELECT * INTO v_table FROM public.seating_tables WHERE id = v_chair.table_id;

  v_token := coalesce(
    (SELECT qr_token FROM public.guests WHERE id = p_guest_id),
    encode(gen_random_bytes(16), 'hex')
  );

  UPDATE public.guests
  SET qr_token = v_token, status = 'pending_media'
  WHERE id = p_guest_id;

  INSERT INTO public.invitations (
    event_id, guest_id, table_id, chair_id,
    invitation_code, web_url, deep_link, qr_payload
  ) VALUES (
    v_guest.event_id, p_guest_id, v_table.id, p_chair_id,
    upper(left(v_token, 4)),
    p_public_base_url || '/guest/' || v_token,
    p_deep_link_base  || '/'      || v_token,
    p_public_base_url || '/guest/' || v_token
  )
  ON CONFLICT (guest_id) DO UPDATE SET
    table_id        = excluded.table_id,
    chair_id        = excluded.chair_id,
    invitation_code = excluded.invitation_code,
    web_url         = excluded.web_url,
    deep_link       = excluded.deep_link,
    qr_payload      = excluded.qr_payload,
    updated_at      = timezone('utc', now())
  RETURNING * INTO v_invitation;

  RETURN v_invitation;
END;
$$;

-- Valide un média et déverrouille la carte si critères atteints
CREATE OR REPLACE FUNCTION public.validate_media_submission(
  p_submission_id          uuid,
  p_server_duration_seconds numeric DEFAULT NULL,
  p_notes                  text     DEFAULT NULL
)
RETURNS TABLE (is_valid boolean, invitation_unlocked boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_submission    public.guest_media_submissions;
  v_client_valid  boolean;
  v_server_valid  boolean;
BEGIN
  UPDATE public.guest_media_submissions
  SET
    server_duration_seconds = coalesce(p_server_duration_seconds, server_duration_seconds, client_duration_seconds),
    validation_notes        = coalesce(p_notes, validation_notes)
  WHERE id = p_submission_id;

  SELECT * INTO v_submission FROM public.guest_media_submissions WHERE id = p_submission_id;
  IF v_submission.id IS NULL THEN RAISE EXCEPTION 'Submission not found'; END IF;

  v_client_valid := v_submission.client_duration_seconds >= 30;
  v_server_valid := coalesce(v_submission.server_duration_seconds, 0) >= 30;

  UPDATE public.guest_media_submissions
  SET client_validated = v_client_valid, server_validated = v_server_valid
  WHERE id = p_submission_id;

  IF v_client_valid AND v_server_valid THEN
    UPDATE public.invitations
    SET is_unlocked = true, unlocked_at = timezone('utc', now())
    WHERE id = v_submission.invitation_id;

    UPDATE public.guests SET status = 'card_unlocked' WHERE id = v_submission.guest_id;
    RETURN QUERY SELECT true, true;
    RETURN;
  END IF;

  UPDATE public.guests SET status = 'media_uploaded' WHERE id = v_submission.guest_id;
  RETURN QUERY SELECT false, false;
END;
$$;

-- Retourne toutes les infos d'une invitation via le token QR
CREATE OR REPLACE FUNCTION public.get_invitation_by_token(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id',               i.id,
    'guest_id',         g.id,
    'guest_name',       g.full_name,
    'table_id',         t.id,
    'table_label',      t.label,
    'chair_id',         c.id,
    'chair_number',     c.chair_number,
    'token',            g.qr_token,
    'invitation_code',  i.invitation_code,
    'web_url',          i.web_url,
    'deep_link',        i.deep_link,
    'is_unlocked',      i.is_unlocked,
    'png_storage_path', i.png_storage_path,
    'pdf_storage_path', i.pdf_storage_path,
    'event', jsonb_build_object(
      'id',               e.id,
      'title',            e.title,
      'bride_name',       e.bride_name,
      'groom_name',       e.groom_name,
      'location',         coalesce(e.location, ''),
      'event_date_label', coalesce(to_char(e.event_date, 'DD Mon YYYY'), '')
    ),
    'media_submissions', coalesce(
      (SELECT jsonb_agg(
        jsonb_build_object(
          'id',                      gm.id,
          'invitation_id',           gm.invitation_id,
          'guest_id',                gm.guest_id,
          'media_type',              gm.media_type,
          'storage_path',            gm.storage_path,
          'client_duration_seconds', gm.client_duration_seconds,
          'server_duration_seconds', gm.server_duration_seconds,
          'client_validated',        gm.client_validated,
          'server_validated',        gm.server_validated,
          'submitted_at',            gm.submitted_at
        ) ORDER BY gm.submitted_at ASC
      )
      FROM public.guest_media_submissions gm
      WHERE gm.invitation_id = i.id),
      '[]'::jsonb
    )
  )
  INTO v_result
  FROM public.guests g
  JOIN public.invitations           i ON i.guest_id  = g.id
  JOIN public.seating_tables        t ON t.id        = i.table_id
  JOIN public.chairs                c ON c.id        = i.chair_id
  JOIN public.wedding_events        e ON e.id        = i.event_id
  WHERE g.qr_token = p_token;

  RETURN v_result;
END;
$$;

-- Soumet un média via token (appelé par l'invité, sans auth)
CREATE OR REPLACE FUNCTION public.submit_guest_media_by_token(
  p_token                    text,
  p_media_type               public.guest_media_type,
  p_storage_path             text,
  p_client_duration_seconds  numeric,
  p_server_duration_seconds  numeric DEFAULT NULL,
  p_mime_type                text    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guest        public.guests;
  v_invitation   public.invitations;
  v_submission_id uuid;
BEGIN
  SELECT * INTO v_guest FROM public.guests WHERE qr_token = p_token;
  IF v_guest.id IS NULL THEN RAISE EXCEPTION 'Invitation token not found'; END IF;

  SELECT * INTO v_invitation FROM public.invitations WHERE guest_id = v_guest.id;
  IF v_invitation.id IS NULL THEN RAISE EXCEPTION 'Invitation not found'; END IF;

  INSERT INTO public.guest_media_submissions (
    event_id, guest_id, invitation_id, media_type, storage_path, mime_type,
    client_duration_seconds, server_duration_seconds,
    client_validated, server_validated
  ) VALUES (
    v_guest.event_id, v_guest.id, v_invitation.id,
    p_media_type, p_storage_path, p_mime_type,
    p_client_duration_seconds,
    coalesce(p_server_duration_seconds, p_client_duration_seconds),
    p_client_duration_seconds >= 30,
    coalesce(p_server_duration_seconds, p_client_duration_seconds) >= 30
  )
  RETURNING id INTO v_submission_id;

  PERFORM public.validate_media_submission(
    v_submission_id,
    coalesce(p_server_duration_seconds, p_client_duration_seconds),
    'Validation via RPC publique par token.'
  );

  RETURN public.get_invitation_by_token(p_token);
END;
$$;

-- Génère un code court aléatoire (8 caractères)
CREATE OR REPLACE FUNCTION public.generate_short_code()
RETURNS varchar(8)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  chars  varchar(56) := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  result varchar(8)  := '';
  i      integer;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

-- Crée un lien court pour un invité (admin uniquement)
CREATE OR REPLACE FUNCTION public.create_guest_link(p_guest_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_guest_token text;
  v_short_code  varchar(8);
  v_link_id     uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  SELECT qr_token INTO v_guest_token FROM public.guests WHERE id = p_guest_id;
  IF v_guest_token IS NULL THEN RAISE EXCEPTION 'Guest not found'; END IF;

  LOOP
    v_short_code := public.generate_short_code();
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.guest_links WHERE short_code = v_short_code);
  END LOOP;

  INSERT INTO public.guest_links (short_code, guest_token, guest_id)
  VALUES (v_short_code, v_guest_token, p_guest_id)
  RETURNING id INTO v_link_id;

  RETURN json_build_object('id', v_link_id, 'short_code', v_short_code, 'guest_token', v_guest_token);
END;
$$;

-- Grants sur les fonctions publiques (invité sans auth)
GRANT EXECUTE ON FUNCTION public.get_invitation_by_token(text)           TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.submit_guest_media_by_token(text, public.guest_media_type, text, numeric, numeric, text)
                                                                          TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_guest_link(uuid)                 TO authenticated;


-- ============================================================
-- 9. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.wedding_events           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guests                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seating_tables           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chairs                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitations              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_media_submissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_links              ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes policies avant de recréer
DO $$
DECLARE pol record;
BEGIN
  FOR pol IN
    SELECT policyname, tablename, schemaname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN (
        'wedding_events','profiles','guests','seating_tables',
        'chairs','invitations','guest_media_submissions','guest_links'
      )
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END $$;

-- wedding_events : admin voit son event
CREATE POLICY "wedding_events_admin_select" ON public.wedding_events
  FOR SELECT TO authenticated
  USING (id = public.current_event_id());

-- profiles : admin gère les profils de son event
CREATE POLICY "profiles_admin_all" ON public.profiles
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

-- profiles : chaque utilisateur peut lire son propre profil
CREATE POLICY "profiles_own_read" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = (SELECT auth.uid()));

-- guests
CREATE POLICY "guests_admin_all" ON public.guests
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

CREATE POLICY "guests_public_read" ON public.guests
  FOR SELECT TO anon USING (true);

-- seating_tables
CREATE POLICY "seating_tables_admin_all" ON public.seating_tables
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

CREATE POLICY "seating_tables_public_read" ON public.seating_tables
  FOR SELECT TO anon USING (true);

-- chairs
CREATE POLICY "chairs_admin_all" ON public.chairs
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

CREATE POLICY "chairs_public_read" ON public.chairs
  FOR SELECT TO anon USING (true);

-- invitations
CREATE POLICY "invitations_admin_all" ON public.invitations
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

-- guest_media_submissions
CREATE POLICY "guest_media_admin_all" ON public.guest_media_submissions
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

-- guest_links : admin gère, anon peut lire les liens actifs
CREATE POLICY "guest_links_admin_all" ON public.guest_links
  FOR ALL TO authenticated
  USING    (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "guest_links_public_read" ON public.guest_links
  FOR SELECT TO anon USING (is_active = true);


-- ============================================================
-- 10. STORAGE BUCKETS & POLICIES
-- ============================================================

INSERT INTO storage.buckets (id, name, public) VALUES
  ('guest-media',            'guest-media',            false),
  ('invitation-cards-png',   'invitation-cards-png',   false),
  ('invitation-cards-pdf',   'invitation-cards-pdf',   false)
ON CONFLICT (id) DO NOTHING;

-- Supprimer les anciennes policies storage
DO $$
DECLARE pol record;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname LIKE ANY(ARRAY[
        'admins_access_%', 'storage_%', 'Admin %', 'Public read %'
      ])
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
  END LOOP;
END $$;

-- Admin : accès complet aux buckets médias et cartes
CREATE POLICY "storage_admin_guest_media" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'guest-media'          AND public.is_admin())
  WITH CHECK (bucket_id = 'guest-media'        AND public.is_admin());

CREATE POLICY "storage_admin_cards_png" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'invitation-cards-png' AND public.is_admin())
  WITH CHECK (bucket_id = 'invitation-cards-png' AND public.is_admin());

CREATE POLICY "storage_admin_cards_pdf" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'invitation-cards-pdf' AND public.is_admin())
  WITH CHECK (bucket_id = 'invitation-cards-pdf' AND public.is_admin());

-- Invité (anon) : peut uploader son propre média
CREATE POLICY "storage_anon_upload_guest_media" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (bucket_id = 'guest-media');


-- ============================================================
-- 11. GRANTS Data API
-- ============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.wedding_events          TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles                TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guests                  TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.seating_tables          TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chairs                  TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitations             TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guest_media_submissions TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guest_links             TO anon, authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
