-- ============================================================
-- Migration 001: Schéma initial Application Mariage Étienne
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
CREATE TABLE IF NOT EXISTS guest_media (
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
CREATE INDEX IF NOT EXISTS idx_guest_media_guest_id ON guest_media(guest_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wedding_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE chairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_media ENABLE ROW LEVEL SECURITY;

-- Policies pour l'admin (via auth.uid())
CREATE POLICY "Admin can manage own profile" ON profiles
  FOR ALL USING (auth.uid() = id);

CREATE POLICY "Admin full access on wedding_tables" ON wedding_tables
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin full access on chairs" ON chairs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin full access on guests" ON guests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin full access on guest_seats" ON guest_seats
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin full access on invitations" ON invitations
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin full access on guest_media" ON guest_media
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
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

-- Storage policies
CREATE POLICY "Admin upload audios" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'guest-audios'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin upload videos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'guest-videos'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Public read cards" ON storage.objects
  FOR SELECT USING (bucket_id = 'invitation-cards' OR bucket_id = 'wedding-assets');

CREATE POLICY "Admin manage cards" ON storage.objects
  FOR ALL USING (
    bucket_id = 'invitation-cards'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Récupérer les infos d'un invité par token (pour l'accès public via QR)
CREATE OR REPLACE FUNCTION get_guest_by_token(token TEXT)
RETURNS JSON AS $$
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
$$ LANGUAGE sql SECURITY DEFINER;

-- Vérifier et valider un média (côté serveur)
CREATE OR REPLACE FUNCTION validate_media(
  p_guest_id UUID,
  p_media_type TEXT,
  p_storage_path TEXT,
  p_duration_seconds INTEGER
)
RETURNS JSON AS $$
DECLARE
  v_is_valid BOOLEAN;
BEGIN
  v_is_valid := p_duration_seconds >= 30;

  INSERT INTO guest_media (guest_id, media_type, storage_path, duration_seconds, is_valid)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
