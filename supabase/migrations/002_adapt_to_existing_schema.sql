-- ============================================================
-- Migration 002: Adaptation au schéma existant
-- ============================================================
-- Le projet distant utilise déjà:
--   - seating_tables (au lieu de wedding_tables)
--   - guest_media_submissions (au lieu de guest_media)
--   - profiles, chairs, guests, invitations existent déjà
-- Il manque: guest_seats
-- ============================================================

-- 1. Créer la table guest_seats si elle n'existe pas
CREATE TABLE IF NOT EXISTS guest_seats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guest_id UUID NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES seating_tables(id) ON DELETE CASCADE,
  chair_id UUID NOT NULL REFERENCES chairs(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(chair_id)
);

-- Index pour guest_seats
CREATE INDEX IF NOT EXISTS idx_guest_seats_guest_id ON guest_seats(guest_id);
CREATE INDEX IF NOT EXISTS idx_guest_seats_table_id ON guest_seats(table_id);

-- 2. GRANT pour toutes les tables existantes + nouvelles
-- (requis depuis le 28/04/2026)
GRANT SELECT, INSERT, UPDATE, DELETE ON profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON seating_tables TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chairs TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guests TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guest_seats TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON invitations TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guest_media_submissions TO anon, authenticated;

-- Séquences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 3. RLS - Activer sur les nouvelles tables
ALTER TABLE guest_seats ENABLE ROW LEVEL SECURITY;

-- 4. Policies pour guest_seats
CREATE POLICY "Admin full access on guest_seats" ON guest_seats
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- 5. Policies RLS pour seating_tables (si pas déjà présente)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'seating_tables' AND policyname = 'Admin full access on seating_tables'
  ) THEN
    CREATE POLICY "Admin full access on seating_tables" ON seating_tables
      FOR ALL
      TO authenticated
      USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      )
      WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;
END $$;

-- 6. Policies RLS pour guest_media_submissions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'guest_media_submissions' AND policyname = 'Admin full access on guest_media_submissions'
  ) THEN
    CREATE POLICY "Admin full access on guest_media_submissions" ON guest_media_submissions
      FOR ALL
      TO authenticated
      USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      )
      WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;
END $$;

-- 7. Lecture publique pour le parcours invité (QR code lookup)
DO $$
BEGIN
  -- Guests: lecture publique pour lookup par token
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'guests' AND policyname = 'Public read guest by token lookup'
  ) THEN
    CREATE POLICY "Public read guest by token lookup" ON guests
      FOR SELECT TO anon USING (true);
  END IF;

  -- seating_tables: lecture publique pour affichage info invité
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'seating_tables' AND policyname = 'Public read tables for guest lookup'
  ) THEN
    CREATE POLICY "Public read tables for guest lookup" ON seating_tables
      FOR SELECT TO anon USING (true);
  END IF;

  -- chairs: lecture publique pour affichage info invité
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'chairs' AND policyname = 'Public read chairs for guest lookup'
  ) THEN
    CREATE POLICY "Public read chairs for guest lookup" ON chairs
      FOR SELECT TO anon USING (true);
  END IF;

  -- guest_seats: lecture publique pour affichage info invité
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'guest_seats' AND policyname = 'Public read seats for guest lookup'
  ) THEN
    CREATE POLICY "Public read seats for guest lookup" ON guest_seats
      FOR SELECT TO anon USING (true);
  END IF;
END $$;

-- 8. Storage policies (si pas déjà présentes)
DO $$
BEGIN
  -- Créer les buckets s'ils n'existent pas
  INSERT INTO storage.buckets (id, name, public) VALUES
    ('guest-audios', 'guest-audios', false),
    ('guest-videos', 'guest-videos', false),
    ('invitation-cards', 'invitation-cards', true),
    ('wedding-assets', 'wedding-assets', true)
  ON CONFLICT (id) DO NOTHING;

  -- Admin upload audios
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Admin upload audios'
  ) THEN
    CREATE POLICY "Admin upload audios" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (
        bucket_id = 'guest-audios'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;

  -- Admin upload videos
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Admin upload videos'
  ) THEN
    CREATE POLICY "Admin upload videos" ON storage.objects
      FOR INSERT TO authenticated
      WITH CHECK (
        bucket_id = 'guest-videos'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;

  -- Public read cards
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Public read cards and assets'
  ) THEN
    CREATE POLICY "Public read cards and assets" ON storage.objects
      FOR SELECT TO anon
      USING (bucket_id = 'invitation-cards' OR bucket_id = 'wedding-assets');
  END IF;

  -- Admin manage cards
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Admin manage cards'
  ) THEN
    CREATE POLICY "Admin manage cards" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'invitation-cards'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      )
      WITH CHECK (
        bucket_id = 'invitation-cards'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;

  -- Admin manage assets
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Admin manage assets'
  ) THEN
    CREATE POLICY "Admin manage assets" ON storage.objects
      FOR ALL TO authenticated
      USING (
        bucket_id = 'wedding-assets'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      )
      WITH CHECK (
        bucket_id = 'wedding-assets'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
      );
  END IF;
END $$;

-- 9. RPC Functions
-- get_guest_by_token: lecture publique via token unique
CREATE OR REPLACE FUNCTION get_guest_by_token(p_token TEXT)
RETURNS JSON
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT json_build_object(
    'id', g.id,
    'full_name', g.full_name,
    'status', g.status,
    'table_name', st.name,
    'chair_number', c.chair_number
  )
  FROM guests g
  LEFT JOIN guest_seats gs ON gs.guest_id = g.id
  LEFT JOIN seating_tables st ON st.id = gs.table_id
  LEFT JOIN chairs c ON c.id = gs.chair_id
  WHERE g.qr_token = p_token;
$$;

-- validate_media: validation côté serveur par admin
CREATE OR REPLACE FUNCTION validate_media(
  p_guest_id UUID,
  p_media_type TEXT,
  p_storage_path TEXT,
  p_duration_seconds INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_is_valid BOOLEAN;
  v_caller_id UUID;
BEGIN
  v_caller_id := auth.uid();
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_caller_id AND role = 'admin') THEN
    RAISE EXCEPTION 'Accès refusé: seuls les administrateurs peuvent valider les médias';
  END IF;

  v_is_valid := p_duration_seconds >= 30;

  INSERT INTO guest_media_submissions (guest_id, media_type, storage_path, duration_seconds, is_valid)
  VALUES (p_guest_id, p_media_type, p_storage_path, p_duration_seconds, v_is_valid);

  IF v_is_valid THEN
    UPDATE guests SET status = 'card_unlocked' WHERE id = p_guest_id;
    UPDATE invitations SET is_unlocked = true WHERE guest_id = p_guest_id;
  ELSE
    UPDATE guests SET status = 'media_uploaded' WHERE id = p_guest_id;
  END IF;

  RETURN json_build_object(
    'is_valid', v_is_valid,
    'status', CASE WHEN v_is_valid THEN 'card_unlocked' ELSE 'media_uploaded' END
  );
END;
$$;

-- Permissions sur les fonctions
REVOKE EXECUTE ON FUNCTION get_guest_by_token(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION validate_media(UUID, TEXT, TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_guest_by_token(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION validate_media(UUID, TEXT, TEXT, INTEGER) TO authenticated;
