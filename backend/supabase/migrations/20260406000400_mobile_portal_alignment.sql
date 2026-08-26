-- Align the Flutter admin application and the public guest portal with the
-- consolidated event-scoped schema.

CREATE OR REPLACE FUNCTION public.create_seating_table(
  p_label text,
  p_capacity integer
)
RETURNS public.seating_tables
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_table public.seating_tables;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  IF nullif(btrim(p_label), '') IS NULL THEN
    RAISE EXCEPTION 'Table label is required';
  END IF;
  IF p_capacity < 1 THEN
    RAISE EXCEPTION 'Table capacity must be positive';
  END IF;

  v_event_id := public.current_event_id();
  IF v_event_id IS NULL THEN
    RAISE EXCEPTION 'No wedding event is attached to this administrator';
  END IF;

  INSERT INTO public.seating_tables(event_id, label, capacity)
  VALUES (v_event_id, btrim(p_label), p_capacity)
  RETURNING * INTO v_table;

  INSERT INTO public.chairs(event_id, table_id, chair_number)
  SELECT v_event_id, v_table.id, number
  FROM generate_series(1, p_capacity) AS number;

  RETURN v_table;
END;
$$;

DROP FUNCTION IF EXISTS public.assign_guest_to_chair(uuid, uuid, text, text);

CREATE FUNCTION public.assign_guest_to_chair(
  p_guest_id uuid,
  p_chair_id uuid,
  p_guest_portal_url text
)
RETURNS public.invitations
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_guest public.guests;
  v_chair public.chairs;
  v_token text;
  v_web_url text;
  v_invitation public.invitations;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  v_event_id := public.current_event_id();
  SELECT * INTO v_guest
  FROM public.guests
  WHERE id = p_guest_id AND event_id = v_event_id;
  IF v_guest.id IS NULL THEN RAISE EXCEPTION 'Guest not found'; END IF;

  SELECT * INTO v_chair
  FROM public.chairs
  WHERE id = p_chair_id AND event_id = v_event_id
  FOR UPDATE;
  IF v_chair.id IS NULL THEN RAISE EXCEPTION 'Chair not found'; END IF;
  IF v_chair.guest_id IS NOT NULL AND v_chair.guest_id <> p_guest_id THEN
    RAISE EXCEPTION 'Chair already assigned';
  END IF;

  UPDATE public.chairs SET guest_id = NULL
  WHERE event_id = v_event_id AND guest_id = p_guest_id;
  UPDATE public.chairs SET guest_id = p_guest_id WHERE id = p_chair_id;

  v_token := coalesce(nullif(v_guest.qr_token, ''), encode(gen_random_bytes(16), 'hex'));
  v_web_url := rtrim(p_guest_portal_url, '/') || '?token=' || v_token;

  UPDATE public.guests
  SET qr_token = v_token,
      status = CASE
        WHEN status IN ('media_uploaded', 'card_unlocked') THEN status
        ELSE 'pending_media'
      END
  WHERE id = p_guest_id;

  INSERT INTO public.invitations(
    event_id, guest_id, table_id, chair_id, invitation_code,
    web_url, deep_link, qr_payload
  ) VALUES (
    v_event_id, p_guest_id, v_chair.table_id, p_chair_id,
    'INV-' || upper(left(encode(digest(v_token, 'sha256'), 'hex'), 16)),
    v_web_url, 'mariageentienne://guest/' || v_token, v_web_url
  )
  ON CONFLICT (guest_id) DO UPDATE SET
    table_id = excluded.table_id,
    chair_id = excluded.chair_id,
    invitation_code = excluded.invitation_code,
    web_url = excluded.web_url,
    deep_link = excluded.deep_link,
    qr_payload = excluded.qr_payload,
    updated_at = timezone('utc', now())
  RETURNING * INTO v_invitation;

  RETURN v_invitation;
END;
$$;

CREATE OR REPLACE FUNCTION public.unassign_guest_from_chair(p_guest_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  v_event_id := public.current_event_id();

  IF EXISTS (
    SELECT 1 FROM public.guest_media_submissions
    WHERE guest_id = p_guest_id AND event_id = v_event_id
  ) THEN
    RAISE EXCEPTION 'A guest with submitted media cannot be unassigned';
  END IF;

  UPDATE public.chairs SET guest_id = NULL
  WHERE event_id = v_event_id AND guest_id = p_guest_id;
  DELETE FROM public.invitations
  WHERE event_id = v_event_id AND guest_id = p_guest_id;
  UPDATE public.guest_links SET is_active = false
  WHERE guest_id = p_guest_id;
  UPDATE public.guests SET status = 'draft'
  WHERE id = p_guest_id AND event_id = v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_seating_table(p_table_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  v_event_id := public.current_event_id();
  IF EXISTS (
    SELECT 1 FROM public.chairs
    WHERE table_id = p_table_id AND event_id = v_event_id AND guest_id IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'An occupied table cannot be deleted';
  END IF;
  DELETE FROM public.seating_tables
  WHERE id = p_table_id AND event_id = v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_guest(p_guest_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  v_event_id := public.current_event_id();
  IF EXISTS (
    SELECT 1 FROM public.guest_media_submissions
    WHERE guest_id = p_guest_id AND event_id = v_event_id
  ) THEN
    RAISE EXCEPTION 'A guest with submitted media cannot be deleted';
  END IF;
  UPDATE public.chairs SET guest_id = NULL
  WHERE guest_id = p_guest_id AND event_id = v_event_id;
  DELETE FROM public.guests
  WHERE id = p_guest_id AND event_id = v_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_guest_link(p_guest_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_guest_token text;
  v_short_code varchar(8);
  v_link public.guest_links;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;
  v_event_id := public.current_event_id();
  PERFORM pg_advisory_xact_lock(hashtextextended(p_guest_id::text, 0));

  SELECT qr_token INTO v_guest_token
  FROM public.guests
  WHERE id = p_guest_id AND event_id = v_event_id;
  IF v_guest_token IS NULL THEN RAISE EXCEPTION 'Guest not found'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.invitations WHERE guest_id = p_guest_id) THEN
    RAISE EXCEPTION 'Assign a chair before creating the invitation link';
  END IF;

  SELECT * INTO v_link
  FROM public.guest_links
  WHERE guest_id = p_guest_id
  ORDER BY created_at, id
  LIMIT 1;
  IF v_link.id IS NULL THEN
    LOOP
      v_short_code := public.generate_short_code();
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM public.guest_links WHERE short_code = v_short_code
      );
    END LOOP;
    INSERT INTO public.guest_links(short_code, guest_token, guest_id)
    VALUES (v_short_code, v_guest_token, p_guest_id)
    RETURNING * INTO v_link;
  ELSE
    UPDATE public.guest_links
    SET guest_token = v_guest_token, is_active = true
    WHERE id = v_link.id
    RETURNING * INTO v_link;
  END IF;

  RETURN to_json(v_link);
END;
$$;

CREATE OR REPLACE FUNCTION public.resolve_guest_link(p_short_code text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_token text;
BEGIN
  UPDATE public.guest_links
  SET scan_count = scan_count + 1,
      last_scanned_at = timezone('utc', now())
  WHERE short_code = p_short_code AND is_active = true
  RETURNING guest_token INTO v_token;
  RETURN v_token;
END;
$$;

REVOKE ALL ON FUNCTION public.create_seating_table(text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.assign_guest_to_chair(uuid, uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.unassign_guest_from_chair(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_seating_table(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_guest(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_guest_link(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resolve_guest_link(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_seating_table(text, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_guest_to_chair(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unassign_guest_from_chair(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_seating_table(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_guest(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_guest_link(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_guest_link(text) TO service_role;

-- Guests only interact through the Edge Function. Do not expose full guest
-- records or guest tokens through anonymous Data API reads.
DROP POLICY IF EXISTS "guests_public_read" ON public.guests;
DROP POLICY IF EXISTS "seating_tables_public_read" ON public.seating_tables;
DROP POLICY IF EXISTS "chairs_public_read" ON public.chairs;
DROP POLICY IF EXISTS "guest_links_public_read" ON public.guest_links;
REVOKE ALL ON public.guests, public.seating_tables, public.chairs,
  public.invitations, public.guest_media_submissions, public.guest_links FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_invitation_by_token(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_invitation_by_token(text) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.submit_guest_media_by_token(
  text, public.guest_media_type, text, numeric, numeric, text
) FROM anon;
REVOKE EXECUTE ON FUNCTION public.submit_guest_media_by_token(
  text, public.guest_media_type, text, numeric, numeric, text
) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.get_invitation_by_token(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.submit_guest_media_by_token(
  text, public.guest_media_type, text, numeric, numeric, text
) TO service_role;

DROP POLICY IF EXISTS "storage_anon_upload_guest_media" ON storage.objects;

DO $$
DECLARE
  table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'guests', 'chairs', 'invitations', 'guest_media_submissions', 'guest_links'
  ]
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
