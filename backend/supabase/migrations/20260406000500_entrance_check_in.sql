-- Common entrance QR managed by the wedding administrator. Guests scan this
-- code at the venue and confirm their own unlocked invitation.

-- Ensure pgcrypto is available (gen_random_bytes)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.event_entrance_codes (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id        uuid        NOT NULL UNIQUE REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  code            text        NOT NULL UNIQUE DEFAULT replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
  is_active       boolean     NOT NULL DEFAULT true,
  scan_count      integer     NOT NULL DEFAULT 0,
  last_scanned_at timestamptz,
  created_by      uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at      timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.guest_check_ins (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          uuid        NOT NULL REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  guest_id          uuid        NOT NULL UNIQUE REFERENCES public.guests(id) ON DELETE RESTRICT,
  entrance_code_id  uuid        NOT NULL REFERENCES public.event_entrance_codes(id) ON DELETE RESTRICT,
  checked_in_at     timestamptz NOT NULL DEFAULT timezone('utc', now()),
  created_at        timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_guest_check_ins_event_id
  ON public.guest_check_ins(event_id);

DROP TRIGGER IF EXISTS trg_event_entrance_codes_updated_at ON public.event_entrance_codes;
CREATE TRIGGER trg_event_entrance_codes_updated_at
  BEFORE UPDATE ON public.event_entrance_codes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE FUNCTION public.manage_entrance_qr(
  p_guest_portal_url text,
  p_rotate boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_code public.event_entrance_codes;
  v_url text;
  v_check_in_count integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  v_event_id := public.current_event_id();
  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'No wedding event is attached to this administrator';
  END IF;

  SELECT * INTO v_code
  FROM public.event_entrance_codes
  WHERE event_id = v_event_id
  FOR UPDATE;

  IF v_code.id IS NULL THEN
    INSERT INTO public.event_entrance_codes(event_id, created_by)
    VALUES (v_event_id, auth.uid())
    RETURNING * INTO v_code;
  ELSIF p_rotate THEN
    UPDATE public.event_entrance_codes
    SET code = replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
        is_active = true,
        scan_count = 0,
        last_scanned_at = NULL
    WHERE id = v_code.id
    RETURNING * INTO v_code;
  ELSIF NOT v_code.is_active THEN
    UPDATE public.event_entrance_codes SET is_active = true
    WHERE id = v_code.id
    RETURNING * INTO v_code;
  END IF;

  v_url := rtrim(p_guest_portal_url, '/') || '?entrance=' || v_code.code;
  SELECT count(*) INTO v_check_in_count
  FROM public.guest_check_ins
  WHERE event_id = v_event_id;

  RETURN jsonb_build_object(
    'id', v_code.id,
    'event_id', v_code.event_id,
    'code', v_code.code,
    'url', v_url,
    'is_active', v_code.is_active,
    'scan_count', v_code.scan_count,
    'check_in_count', v_check_in_count,
    'last_scanned_at', v_code.last_scanned_at,
    'created_at', v_code.created_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_entrance_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code public.event_entrance_codes;
  v_event public.wedding_events;
BEGIN
  UPDATE public.event_entrance_codes
  SET scan_count = scan_count + 1,
      last_scanned_at = timezone('utc', now())
  WHERE code = p_code AND is_active = true
  RETURNING * INTO v_code;
  IF v_code.id IS NULL THEN RETURN NULL; END IF;

  SELECT * INTO v_event FROM public.wedding_events WHERE id = v_code.event_id;
  RETURN jsonb_build_object(
    'event_id', v_event.id,
    'title', v_event.title,
    'bride_name', v_event.bride_name,
    'groom_name', v_event.groom_name,
    'location', coalesce(v_event.location, ''),
    'event_date_label', coalesce(to_char(v_event.event_date, 'DD Mon YYYY'), '')
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.check_in_guest(
  p_entrance_code text,
  p_invitation_identifier text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_code public.event_entrance_codes;
  v_invitation public.invitations;
  v_guest public.guests;
  v_table public.seating_tables;
  v_chair public.chairs;
  v_check_in public.guest_check_ins;
  v_already_checked_in boolean;
BEGIN
  SELECT * INTO v_code
  FROM public.event_entrance_codes
  WHERE code = p_entrance_code AND is_active = true;
  IF v_code.id IS NULL THEN RAISE EXCEPTION 'Entrance QR code is invalid or inactive'; END IF;

  SELECT i.* INTO v_invitation
  FROM public.invitations i
  JOIN public.guests g ON g.id = i.guest_id
  WHERE i.event_id = v_code.event_id
    AND (
      g.qr_token = btrim(p_invitation_identifier)
      OR upper(i.invitation_code) = upper(btrim(p_invitation_identifier))
    )
  LIMIT 1;
  IF v_invitation.id IS NULL THEN RAISE EXCEPTION 'Invitation not found'; END IF;
  SELECT * INTO v_guest FROM public.guests WHERE id = v_invitation.guest_id;
  IF NOT v_invitation.is_unlocked THEN
    RAISE EXCEPTION 'Invitation card must be unlocked before check-in';
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM public.guest_check_ins WHERE guest_id = v_guest.id
  ) INTO v_already_checked_in;

  INSERT INTO public.guest_check_ins(event_id, guest_id, entrance_code_id)
  VALUES (v_code.event_id, v_guest.id, v_code.id)
  ON CONFLICT (guest_id) DO NOTHING;

  SELECT * INTO v_check_in
  FROM public.guest_check_ins WHERE guest_id = v_guest.id;
  SELECT * INTO v_table FROM public.seating_tables WHERE id = v_invitation.table_id;
  SELECT * INTO v_chair FROM public.chairs WHERE id = v_invitation.chair_id;

  RETURN jsonb_build_object(
    'guest_name', v_guest.full_name,
    'invitation_code', v_invitation.invitation_code,
    'table_label', v_table.label,
    'chair_number', v_chair.chair_number,
    'checked_in_at', v_check_in.checked_in_at,
    'already_checked_in', v_already_checked_in
  );
END;
$$;

ALTER TABLE public.event_entrance_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "entrance_codes_admin_select" ON public.event_entrance_codes
  FOR SELECT TO authenticated
  USING (public.is_admin() AND event_id = public.current_event_id());

CREATE POLICY "guest_check_ins_admin_select" ON public.guest_check_ins
  FOR SELECT TO authenticated
  USING (public.is_admin() AND event_id = public.current_event_id());

REVOKE ALL ON public.event_entrance_codes, public.guest_check_ins FROM anon;
GRANT SELECT ON public.event_entrance_codes, public.guest_check_ins TO authenticated;
REVOKE ALL ON FUNCTION public.manage_entrance_qr(text, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_entrance_code(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_in_guest(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_entrance_qr(text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_entrance_code(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.check_in_guest(text, text) TO service_role;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['event_entrance_codes', 'guest_check_ins']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = table_name
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', table_name);
    END IF;
  END LOOP;
END $$;
