-- RSVP des invités : le couple envoie d'abord une invitation « light » avec
-- une date limite pour répondre, puis place à table les invités qui ont
-- confirmé. guests.rsvp_status / rsvp_responded_at complètent guests.status
-- (flux média / carte) sans le détourner, et wedding_events.rsvp_deadline
-- porte la date limite affichée dans les messages et sur le portail.

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS rsvp_deadline timestamptz;

ALTER TABLE public.guests
  ADD COLUMN IF NOT EXISTS rsvp_status text NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS rsvp_responded_at timestamptz;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'guests_rsvp_status_check'
      AND conrelid = 'public.guests'::regclass
  ) THEN
    ALTER TABLE public.guests
      ADD CONSTRAINT guests_rsvp_status_check
      CHECK (rsvp_status IN ('pending', 'confirmed', 'declined'));
  END IF;
END $$;

-- Enregistre la réponse d'un invité (présent / absent) via son token.
-- Renvoie l'invitation enrichie pour que le portail rafraîchisse son état.
CREATE OR REPLACE FUNCTION public.set_guest_rsvp_by_token(
  p_token text,
  p_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_guest public.guests;
BEGIN
  IF p_status NOT IN ('confirmed', 'declined') THEN
    RAISE EXCEPTION 'Invalid rsvp status';
  END IF;

  SELECT * INTO v_guest
  FROM public.guests
  WHERE id = public.resolve_guest_id_by_token(p_token);

  IF v_guest.id IS NULL OR v_guest.status = 'cancelled' THEN
    RAISE EXCEPTION 'Invitation token not found';
  END IF;

  UPDATE public.guests
     SET rsvp_status = p_status,
         rsvp_responded_at = timezone('utc', now())
   WHERE id = v_guest.id;

  RETURN public.get_invitation_by_token(p_token);
END;
$$;

REVOKE ALL ON FUNCTION public.set_guest_rsvp_by_token(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_guest_rsvp_by_token(text, text) TO service_role;

-- get_invitation_by_token expose désormais l'état de réponse de l'invité et
-- la date limite de réponse de l'événement, y compris quand l'invité n'a pas
-- encore de table attribuée (lien d'invitation créé avant le placement).
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
    'rsvp_status', g.rsvp_status,
    'rsvp_responded_at', g.rsvp_responded_at,
    'event', jsonb_build_object(
      'id', e.id,
      'title', e.title,
      'bride_name', e.bride_name,
      'groom_name', e.groom_name,
      'location', coalesce(e.location, ''),
      'event_date_label', coalesce(to_char(e.event_date, 'DD Mon YYYY'), ''),
      'rsvp_deadline_label', coalesce(to_char(e.rsvp_deadline, 'DD Mon YYYY'), '')
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
