-- Un invité peut ouvrir son lien et enregistrer son message avant d'être placé
-- à une table : il n'a alors pas encore de ligne invitations. submit_guest_media_by_token
-- levait "Invitation not found" dans ce cas, alors que get_invitation_by_token
-- (rendu tolérant par 20260829000000) avait laissé l'invité arriver jusqu'à l'envoi.
-- Le message est désormais accepté sans invitation ; il est rattaché, et la carte
-- débloquée, dès que l'invité reçoit sa place.
ALTER TABLE public.guest_media_submissions
  ALTER COLUMN invitation_id DROP NOT NULL;

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

  -- Peut ne pas exister encore : l'invité n'est pas forcément placé.
  SELECT * INTO v_invitation
  FROM public.invitations
  WHERE guest_id = v_guest.id;

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

REVOKE ALL ON FUNCTION public.submit_guest_media_by_token(
  text, public.guest_media_type, text, numeric, numeric, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_guest_media_by_token(
  text, public.guest_media_type, text, numeric, numeric, text
) TO service_role;

-- Quand l'invitation est créée (placement de l'invité), on rattache les messages
-- déjà envoyés et on débloque la carte si l'un d'eux a été validé.
CREATE OR REPLACE FUNCTION public.attach_pending_media_to_invitation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.guest_media_submissions
  SET invitation_id = NEW.id
  WHERE guest_id = NEW.guest_id AND invitation_id IS NULL;

  IF EXISTS (
    SELECT 1 FROM public.guest_media_submissions
    WHERE guest_id = NEW.guest_id
      AND client_validated AND server_validated
  ) THEN
    UPDATE public.invitations
    SET is_unlocked = true, unlocked_at = timezone('utc', now())
    WHERE id = NEW.id AND NOT is_unlocked;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_attach_pending_media ON public.invitations;
CREATE TRIGGER trg_attach_pending_media
  AFTER INSERT ON public.invitations
  FOR EACH ROW EXECUTE FUNCTION public.attach_pending_media_to_invitation();
