-- Les liens courts historiques stockent leur token dans guest_links.guest_token,
-- alors que le portail cherchait uniquement guests.qr_token. Résoudre les deux
-- formats permet de conserver les QR déjà distribués.
CREATE OR REPLACE FUNCTION public.resolve_guest_id_by_token(p_token text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT g.id
  FROM public.guests g
  WHERE g.qr_token = btrim(p_token)
  UNION ALL
  SELECT gl.guest_id
  FROM public.guest_links gl
  WHERE gl.guest_token = btrim(p_token)
    AND gl.is_active = true
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.resolve_guest_id_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_guest_id_by_token(text) TO service_role;

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
    'id', i.id,
    'guest_id', g.id,
    'guest_name', g.full_name,
    'table_id', t.id,
    'table_label', t.label,
    'chair_id', c.id,
    'chair_number', c.chair_number,
    'token', g.qr_token,
    'invitation_code', i.invitation_code,
    'web_url', i.web_url,
    'deep_link', i.deep_link,
    'is_unlocked', i.is_unlocked,
    'png_storage_path', i.png_storage_path,
    'pdf_storage_path', i.pdf_storage_path,
    'event', jsonb_build_object(
      'id', e.id,
      'title', e.title,
      'bride_name', e.bride_name,
      'groom_name', e.groom_name,
      'location', coalesce(e.location, ''),
      'event_date_label', coalesce(to_char(e.event_date, 'DD Mon YYYY'), '')
    ),
    'media_submissions', coalesce(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', gm.id,
            'invitation_id', gm.invitation_id,
            'guest_id', gm.guest_id,
            'media_type', gm.media_type,
            'storage_path', gm.storage_path,
            'client_duration_seconds', gm.client_duration_seconds,
            'server_duration_seconds', gm.server_duration_seconds,
            'client_validated', gm.client_validated,
            'server_validated', gm.server_validated,
            'submitted_at', gm.submitted_at
          ) ORDER BY gm.submitted_at ASC
        )
        FROM public.guest_media_submissions gm
        WHERE gm.invitation_id = i.id
      ),
      '[]'::jsonb
    )
  )
  INTO v_result
  FROM public.guests g
  JOIN public.invitations i ON i.guest_id = g.id
  JOIN public.seating_tables t ON t.id = i.table_id
  JOIN public.chairs c ON c.id = i.chair_id
  JOIN public.wedding_events e ON e.id = i.event_id
  WHERE g.id = public.resolve_guest_id_by_token(p_token);

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_guest_media_by_token(
  p_token text,
  p_media_type public.guest_media_type,
  p_storage_path text,
  p_client_duration_seconds numeric,
  p_server_duration_seconds numeric DEFAULT NULL,
  p_mime_type text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guest public.guests;
  v_invitation public.invitations;
  v_submission_id uuid;
BEGIN
  SELECT * INTO v_guest
  FROM public.guests
  WHERE id = public.resolve_guest_id_by_token(p_token);

  IF v_guest.id IS NULL THEN
    RAISE EXCEPTION 'Invitation token not found';
  END IF;

  SELECT * INTO v_invitation
  FROM public.invitations
  WHERE guest_id = v_guest.id;

  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invitation not found';
  END IF;

  INSERT INTO public.guest_media_submissions (
    event_id,
    guest_id,
    invitation_id,
    media_type,
    storage_path,
    mime_type,
    client_duration_seconds,
    server_duration_seconds,
    client_validated,
    server_validated
  )
  VALUES (
    v_guest.event_id,
    v_guest.id,
    v_invitation.id,
    p_media_type,
    p_storage_path,
    p_mime_type,
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

REVOKE ALL ON FUNCTION public.get_invitation_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_invitation_by_token(text) TO service_role;
REVOKE ALL ON FUNCTION public.submit_guest_media_by_token(
  text,
  public.guest_media_type,
  text,
  numeric,
  numeric,
  text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_guest_media_by_token(
  text,
  public.guest_media_type,
  text,
  numeric,
  numeric,
  text
) TO service_role;
