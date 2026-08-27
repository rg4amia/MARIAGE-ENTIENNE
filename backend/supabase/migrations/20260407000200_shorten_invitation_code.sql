-- Shorten invitation code from 16 to 8 characters
-- Update assign_guest_to_chair function

CREATE OR REPLACE FUNCTION public.assign_guest_to_chair(
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

  -- Unassign guest from any other chair first
  UPDATE public.chairs SET guest_id = NULL
  WHERE event_id = v_event_id AND guest_id = p_guest_id;

  -- Assign to new chair
  UPDATE public.chairs SET guest_id = p_guest_id WHERE id = p_chair_id;

  -- Generate token and short code
  v_token := coalesce(
    nullif(v_guest.qr_token, ''),
    encode(gen_random_bytes(16), 'hex')
  );
  v_web_url := rtrim(p_guest_portal_url, '/') || '?token=' || v_token;

  -- Update guest
  UPDATE public.guests
  SET qr_token = v_token,
      status = CASE
        WHEN status IN ('media_uploaded', 'card_unlocked') THEN status
        ELSE 'pending_media'
      END
  WHERE id = p_guest_id;

  -- Create or update invitation with SHORT code (8 chars)
  INSERT INTO public.invitations(
    event_id, guest_id, table_id, chair_id, invitation_code,
    web_url, deep_link, qr_payload
  ) VALUES (
    v_event_id, p_guest_id, v_chair.table_id, p_chair_id,
    'INV-' || upper(left(encode(digest(v_token, 'sha256'), 'hex'), 4)),
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

GRANT EXECUTE ON FUNCTION public.assign_guest_to_chair(uuid, uuid, text) TO authenticated;
