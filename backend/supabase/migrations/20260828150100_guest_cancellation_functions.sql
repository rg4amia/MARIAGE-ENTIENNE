-- Fonctions de résolution et d'annulation. Séparée de l'ajout de l'enum afin
-- que PostgreSQL puisse valider la nouvelle valeur enum dans une transaction.
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
    AND g.status <> 'cancelled'
  UNION ALL
  SELECT gl.guest_id
  FROM public.guest_links gl
  JOIN public.guests g ON g.id = gl.guest_id
  WHERE gl.guest_token = btrim(p_token)
    AND gl.is_active = true
    AND g.status <> 'cancelled'
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.set_guest_cancelled(
  p_guest_id uuid,
  p_cancelled boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_id uuid;
  v_guest public.guests;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  v_event_id := public.current_event_id();
  SELECT * INTO v_guest
  FROM public.guests
  WHERE id = p_guest_id AND event_id = v_event_id
  FOR UPDATE;

  IF v_guest.id IS NULL THEN
    RAISE EXCEPTION 'Guest not found';
  END IF;

  IF p_cancelled THEN
    IF v_guest.status <> 'cancelled' THEN
      UPDATE public.guests
      SET status_before_cancellation = v_guest.status,
          status = 'cancelled',
          cancelled_at = timezone('utc', now())
      WHERE id = p_guest_id;
    END IF;

    UPDATE public.chairs
    SET guest_id = NULL
    WHERE guest_id = p_guest_id AND event_id = v_event_id;

    UPDATE public.guest_links
    SET is_active = false
    WHERE guest_id = p_guest_id;
  ELSE
    UPDATE public.guests
    SET status = coalesce(status_before_cancellation, 'draft'),
        status_before_cancellation = NULL,
        cancelled_at = NULL
    WHERE id = p_guest_id;

    UPDATE public.guest_links
    SET is_active = true
    WHERE guest_id = p_guest_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.set_guest_cancelled(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_guest_cancelled(uuid, boolean) TO authenticated;
