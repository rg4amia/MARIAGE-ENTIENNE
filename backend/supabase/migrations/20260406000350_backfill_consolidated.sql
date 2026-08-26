-- ============================================================
-- Migration 003.5 : Rattrapage des objets de 000300 non exécutés
-- ============================================================
-- La migration 000300 a été marquée "applied" via repair sans
-- être réellement exécutée. Ce fichier crée les objets manquants
-- par rapport à ce qui existait déjà depuis 000100.
-- ============================================================

-- ── Table guest_links ────────────────────────────────────────
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

CREATE INDEX IF NOT EXISTS idx_guest_links_short_code ON public.guest_links(short_code);
CREATE INDEX IF NOT EXISTS idx_guest_links_guest_id   ON public.guest_links(guest_id);

ALTER TABLE public.guest_links ENABLE ROW LEVEL SECURITY;

-- ── is_admin() — JWT-based, aucune récursion RLS ─────────────
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

-- ── Trigger nouvel utilisateur → profil + JWT app_metadata ───
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  WHERE id = NEW.id;

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

-- Mettre à jour les utilisateurs existants
UPDATE auth.users
SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
WHERE raw_app_meta_data ->> 'role' IS DISTINCT FROM 'admin';

-- ── generate_short_code() ─────────────────────────────────────
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

-- ── Policies guest_links ─────────────────────────────────────
CREATE POLICY "guest_links_admin_all" ON public.guest_links
  FOR ALL TO authenticated
  USING    (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "guest_links_public_read" ON public.guest_links
  FOR SELECT TO anon USING (is_active = true);

-- ── Grants guest_links ───────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guest_links TO anon, authenticated;

-- ── Mettre à jour les policies RLS qui utilisaient current_event_id()
-- sur les tables dont les policies originales (000100) ne filtraient
-- pas par event_id — on les remplace proprement ──────────────

-- profiles
DROP POLICY IF EXISTS "admins_manage_profiles"  ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_all"       ON public.profiles;
DROP POLICY IF EXISTS "profiles_own_read"        ON public.profiles;

CREATE POLICY "profiles_admin_all" ON public.profiles
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

CREATE POLICY "profiles_own_read" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = (SELECT auth.uid()));

-- guests
DROP POLICY IF EXISTS "admins_manage_guests" ON public.guests;
DROP POLICY IF EXISTS "guests_admin_all"     ON public.guests;

CREATE POLICY "guests_admin_all" ON public.guests
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

DROP POLICY IF EXISTS "guests_public_read" ON public.guests;
CREATE POLICY "guests_public_read" ON public.guests
  FOR SELECT TO anon USING (true);

-- seating_tables
DROP POLICY IF EXISTS "admins_manage_tables"       ON public.seating_tables;
DROP POLICY IF EXISTS "seating_tables_admin_all"   ON public.seating_tables;

CREATE POLICY "seating_tables_admin_all" ON public.seating_tables
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

DROP POLICY IF EXISTS "seating_tables_public_read" ON public.seating_tables;
CREATE POLICY "seating_tables_public_read" ON public.seating_tables
  FOR SELECT TO anon USING (true);

-- chairs
DROP POLICY IF EXISTS "admins_manage_chairs" ON public.chairs;
DROP POLICY IF EXISTS "chairs_admin_all"     ON public.chairs;

CREATE POLICY "chairs_admin_all" ON public.chairs
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

DROP POLICY IF EXISTS "chairs_public_read" ON public.chairs;
CREATE POLICY "chairs_public_read" ON public.chairs
  FOR SELECT TO anon USING (true);

-- invitations
DROP POLICY IF EXISTS "admins_manage_invitations" ON public.invitations;
DROP POLICY IF EXISTS "invitations_admin_all"     ON public.invitations;

CREATE POLICY "invitations_admin_all" ON public.invitations
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

-- guest_media_submissions
DROP POLICY IF EXISTS "admins_manage_media"    ON public.guest_media_submissions;
DROP POLICY IF EXISTS "guest_media_admin_all"  ON public.guest_media_submissions;

CREATE POLICY "guest_media_admin_all" ON public.guest_media_submissions
  FOR ALL TO authenticated
  USING    (public.is_admin() AND event_id = public.current_event_id())
  WITH CHECK (public.is_admin() AND event_id = public.current_event_id());

-- ── Storage : remplacer les policies larges de 000100 ─────────
DROP POLICY IF EXISTS "admins_access_guest_media_bucket" ON storage.objects;
DROP POLICY IF EXISTS "admins_access_png_bucket"         ON storage.objects;
DROP POLICY IF EXISTS "admins_access_pdf_bucket"         ON storage.objects;

CREATE POLICY "storage_admin_guest_media" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'guest-media'            AND public.is_admin())
  WITH CHECK (bucket_id = 'guest-media'          AND public.is_admin());

CREATE POLICY "storage_admin_cards_png" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'invitation-cards-png'   AND public.is_admin())
  WITH CHECK (bucket_id = 'invitation-cards-png' AND public.is_admin());

CREATE POLICY "storage_admin_cards_pdf" ON storage.objects
  FOR ALL TO authenticated
  USING    (bucket_id = 'invitation-cards-pdf'   AND public.is_admin())
  WITH CHECK (bucket_id = 'invitation-cards-pdf' AND public.is_admin());

CREATE POLICY "storage_anon_upload_guest_media" ON storage.objects
  FOR INSERT TO anon
  WITH CHECK (bucket_id = 'guest-media');
