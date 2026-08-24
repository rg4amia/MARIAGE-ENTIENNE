-- Table for guest invite short links
-- Maps short_code → guest_token for clean QR codes
CREATE TABLE IF NOT EXISTS public.guest_links (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  short_code VARCHAR(8) NOT NULL UNIQUE,
  guest_token TEXT NOT NULL,
  guest_id UUID NOT NULL REFERENCES public.guests(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT true,
  scan_count INTEGER DEFAULT 0,
  last_scanned_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Ensure short_code is unique
  CONSTRAINT guest_links_short_code_key UNIQUE (short_code)
);

-- Index for fast lookup by short_code
CREATE INDEX IF NOT EXISTS idx_guest_links_short_code ON public.guest_links(short_code);
CREATE INDEX IF NOT EXISTS idx_guest_links_guest_id ON public.guest_links(guest_id);

-- RLS policies
ALTER TABLE public.guest_links ENABLE ROW LEVEL SECURITY;

-- Admin can do everything
CREATE POLICY "Admin can manage guest links" ON public.guest_links
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid() AND profiles.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.user_id = auth.uid() AND profiles.role = 'admin'
    )
  );

-- Public can read active links (for the Edge Function)
CREATE POLICY "Public can read active guest links" ON public.guest_links
  FOR SELECT
  TO anon
  USING (is_active = true);

-- GRANT for Data API access (Supabase breaking change April 2026)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guest_links TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.guest_links TO authenticated;

-- Function to generate a unique short code
CREATE OR REPLACE FUNCTION public.generate_short_code()
RETURNS VARCHAR(8) AS $$
DECLARE
  chars VARCHAR(32) := 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  result VARCHAR(8) := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Function to create a guest link (admin only)
CREATE OR REPLACE FUNCTION public.create_guest_link(
  p_guest_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_guest_token TEXT;
  v_short_code VARCHAR(8);
  v_link_id UUID;
BEGIN
  -- Check admin auth
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE user_id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  -- Get guest token
  SELECT qr_token INTO v_guest_token
  FROM public.guests
  WHERE id = p_guest_id;

  IF v_guest_token IS NULL THEN
    RAISE EXCEPTION 'Guest not found';
  END IF;

  -- Generate unique short code
  LOOP
    v_short_code := public.generate_short_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.guest_links WHERE short_code = v_short_code
    );
  END LOOP;

  -- Insert the link
  INSERT INTO public.guest_links (short_code, guest_token, guest_id)
  VALUES (v_short_code, v_guest_token, p_guest_id)
  RETURNING id INTO v_link_id;

  RETURN json_build_object(
    'id', v_link_id,
    'short_code', v_short_code,
    'guest_token', v_guest_token
  );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
