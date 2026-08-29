-- Un lien d'invitation (guest_links / qr_token) peut être généré depuis
-- l'app (fiche invité, QR code) avant même que l'invité soit placé à une
-- table. get_invitation_by_token faisait un INNER JOIN sur invitations,
-- seating_tables et chairs : un invité pas encore placé n'a pas de ligne
-- invitations, donc la fonction renvoyait NULL et le portail affichait
-- "Invitation introuvable" alors que le token était parfaitement valide.
-- On passe en LEFT JOIN et on retombe sur l'événement de l'invité
-- (guests.event_id) quand aucune invitation n'existe encore.
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
    'is_unlocked', coalesce(i.is_unlocked, false),
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
  LEFT JOIN public.invitations i ON i.guest_id = g.id
  LEFT JOIN public.seating_tables t ON t.id = i.table_id
  LEFT JOIN public.chairs c ON c.id = i.chair_id
  LEFT JOIN public.wedding_events e ON e.id = coalesce(i.event_id, g.event_id)
  WHERE g.id = public.resolve_guest_id_by_token(p_token);

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_invitation_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_invitation_by_token(text) TO service_role;
