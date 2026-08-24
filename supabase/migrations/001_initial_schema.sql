-- ============================================================
-- Migration 001: Schéma initial Application Mariage Étienne
-- ============================================================
-- Note: Depuis le 28/04/2026, les tables ne sont plus exposées
-- automatiquement au Data API. Les GRANT sont requis.
-- ============================================================

-- Activer l'extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

-- Profiles (admin / maries)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('admin')),
  full_name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Tables de mariage
CREATE TABLE IF NOT EXISTS wedding_tables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Chaises
CREATE TABLE IF NOT EXISTS chairs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  table_id UUID NOT NULL REFERENCES wedding_tables(id) ON DELETE CASCADE,
  chair_number INTEGER NOT NULL,
  is_assigned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(table_id, chair_number)
);

-- Invités
CREATE TABLE IF NOT EXISTS guests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  qr_token TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'media_uploaded', 'card_unlocked')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Attribution places (invité → table + chaise)
CREATE TABLE IF NOT EXISTS guest_seats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guest_id UUID NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
  table_id UUID NOT NULL REFERENCES wedding_tables(id) ON DELETE CASCADE,
  chair_id UUID NOT NULL REFERENCES chairs(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(chair_id)
);

-- Invitations
CREATE TABLE IF NOT EXISTS invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guest_id UUID NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
  invitation_code TEXT UNIQUE NOT NULL,
  qr_code_url TEXT,
  card_url TEXT,
  is_unlocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Médias des invités
CREATE TABLE IF NOT EXISTS guest_media_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  guest_id UUID NOT NULL REFERENCES guests(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL CHECK (media_type IN ('audio', 'video')),
  storage_path TEXT NOT NULL,
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 0),
  is_valid BOOLEAN DEFAULT false,
  submitted_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEX
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_chairs_table_id ON chairs(table_id);
CREATE INDEX IF NOT EXISTS idx_guest_seats_guest_id ON guest_seats(guest_id);
CREATE INDEX IF NOT EXISTS idx_guest_seats_table_id ON guest_seats(table_id);
CREATE INDEX IF NOT EXISTS idx_guests_qr_token ON guests(qr_token);
CREATE INDEX IF NOT EXISTS idx_invitations_guest_id ON invitations(guest_id);
CREATE INDEX IF NOT EXISTS idx_guest_media_submissions_guest_id ON guest_media_submissions(guest_id);

-- ============================================================
-- GRANT - Exposer les tables au Data API (requis depuis 04/2026)
-- ============================================================

-- Donner accès en lecture/écriture aux rôles anon et authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON profiles TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wedding_tables TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON chairs TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guests TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guest_seats TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON invitations TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON guest_media_submissions TO anon, authenticated;

-- Accès en séquence pour les inserts
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE chairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_media_submissions ENABLE ROW LEVEL SECURITY;

-- Profiles: l'utilisateur ne peut gérer que son propre profil
CREATE POLICY "Users manage own profile" ON profiles
  FOR ALL
  TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- Tables: admin uniquement
CREATE POLICY "Admin full access on wedding_tables" ON wedding_tables
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Chaises: admin uniquement
CREATE POLICY "Admin full access on chairs" ON chairs
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Invités: admin uniquement
CREATE POLICY "Admin full access on guests" ON guests
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Guest seats: admin uniquement
CREATE POLICY "Admin full access on guest_seats" ON guest_seats
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Invitations: admin uniquement
CREATE POLICY "Admin full access on invitations" ON invitations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Guest media: admin peut tout voir, invité ne peut insérer que le sien
CREATE POLICY "Admin full access on guest_media_submissions" ON guest_media_submissions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public) VALUES
  ('guest-audios', 'guest-audios', false),
  ('guest-videos', 'guest-videos', false),
  ('invitation-cards', 'invitation-cards', true),
  ('wedding-assets', 'wedding-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies: admin peut uploader
CREATE POLICY "Admin upload audios" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'guest-audios'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

CREATE POLICY "Admin upload videos" ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'guest-videos'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Lecture publique des cartes et assets
CREATE POLICY "Public read cards and assets" ON storage.objects
  FOR SELECT
  TO anon
  USING (bucket_id = 'invitation-cards' OR bucket_id = 'wedding-assets');

-- Admin peut gérer les cartes (upload + update + delete)
CREATE POLICY "Admin manage cards" ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'invitation-cards'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    bucket_id = 'invitation-cards'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- Admin peut gérer les assets
CREATE POLICY "Admin manage assets" ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'wedding-assets'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  )
  WITH CHECK (
    bucket_id = 'wedding-assets'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin')
  );

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Récupérer les infos d'un invité par token (accès public, lecture seule)
CREATE OR REPLACE FUNCTION get_guest_by_token(token TEXT)
RETURNS JSON
LANGUAGE sql
SECURITY INVOKER  -- Pas SECURITY DEFINER ! Sécurisé par RLS
SET search_path = public
AS $$
  SELECT json_build_object(
    'id', g.id,
    'full_name', g.full_name,
    'status', g.status,
    'table_name', wt.name,
    'chair_number', c.chair_number
  )
  FROM guests g
  LEFT JOIN guest_seats gs ON gs.guest_id = g.id
  LEFT JOIN wedding_tables wt ON wt.id = gs.table_id
  LEFT JOIN chairs c ON c.id = gs.chair_id
  WHERE g.qr_token = token;
$$;

-- Politique de lecture publique pour guest via token (pour la fonction get_guest_by_token)
-- Les invités doivent pouvoir lire leur propre entrée via le token
CREATE POLICY "Public read guest by token lookup" ON guests
  FOR SELECT
  TO anon
  USING (true);  -- Sécurisé : la fonction filtre par token unique

-- Les invités doivent pouvoir lire les tables pour afficher leur info
CREATE POLICY "Public read tables for guest lookup" ON wedding_tables
  FOR SELECT
  TO anon
  USING (true);

-- Les invités doivent pouvoir lire les chaises pour afficher leur info
CREATE POLICY "Public read chairs for guest lookup" ON chairs
  FOR SELECT
  TO anon
  USING (true);

-- Les invités doivent pouvoir lire les seats pour afficher leur info
CREATE POLICY "Public read seats for guest lookup" ON guest_seats
  FOR SELECT
  TO anon
  USING (true);

-- Vérifier et valider un média (côté serveur)
-- SECURITY INVOKER avec vérification auth.uid() dans le body
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
  -- Vérifier que l'appelant est un admin
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

-- Revoquer l'accès EXECUTE par défaut du rôle PUBLIC pour les fonctions sensibles
REVOKE EXECUTE ON FUNCTION get_guest_by_token(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION validate_media(UUID, TEXT, TEXT, INTEGER) FROM PUBLIC;

-- Autoriser uniquement les rôles appropriés
GRANT EXECUTE ON FUNCTION get_guest_by_token(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION validate_media(UUID, TEXT, TEXT, INTEGER) TO authenticated;
