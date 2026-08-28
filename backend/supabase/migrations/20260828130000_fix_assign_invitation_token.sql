-- Correction robuste de l'assignation d'une chaise.
-- Certains environnements Supabase exposent pgcrypto dans `extensions`;
-- gen_random_uuid() est disponible dans PostgreSQL et ne dépend d'aucun
-- search_path d'extension.

ALTER TABLE public.guests
  ALTER COLUMN qr_token
  SET DEFAULT replace(gen_random_uuid()::text, '-', '');

-- Rattrape les places créées par l'ancien client (chaise mise à jour sans
-- invitation). La sélection est déterministe si une donnée historique a
-- accidentellement placé le même invité sur plusieurs chaises.
UPDATE public.guests g
SET qr_token = replace(gen_random_uuid()::text, '-', '')
FROM (
  SELECT DISTINCT ON (guest_id) guest_id
  FROM public.chairs
  WHERE guest_id IS NOT NULL
  ORDER BY guest_id, updated_at DESC NULLS LAST, id DESC
) assigned
WHERE g.id = assigned.guest_id
  AND nullif(g.qr_token, '') IS NULL;

INSERT INTO public.invitations (
  event_id, guest_id, table_id, chair_id, invitation_code,
  web_url, deep_link, qr_payload
)
SELECT
  c.event_id,
  c.guest_id,
  c.table_id,
  c.id,
  'INV-' || upper(left(md5(g.qr_token), 4)),
  'https://rg4amia.github.io/MARIAGE-ENTIENNE/?token=' || g.qr_token,
  'mariageentienne://guest/' || g.qr_token,
  'https://rg4amia.github.io/MARIAGE-ENTIENNE/?token=' || g.qr_token
FROM (
  SELECT DISTINCT ON (guest_id) *
  FROM public.chairs
  WHERE guest_id IS NOT NULL
  ORDER BY guest_id, updated_at DESC NULLS LAST, id DESC
) c
JOIN public.guests g ON g.id = c.guest_id
WHERE nullif(g.qr_token, '') IS NOT NULL
ON CONFLICT (guest_id) DO NOTHING;

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

  UPDATE public.chairs
  SET guest_id = NULL
  WHERE event_id = v_event_id AND guest_id = p_guest_id;

  UPDATE public.chairs
  SET guest_id = p_guest_id
  WHERE id = p_chair_id;

  v_token := coalesce(
    nullif(v_guest.qr_token, ''),
    replace(gen_random_uuid()::text, '-', '')
  );
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
    v_event_id,
    p_guest_id,
    v_chair.table_id,
    p_chair_id,
    'INV-' || upper(left(md5(v_token), 4)),
    v_web_url,
    'mariageentienne://guest/' || v_token,
    v_web_url
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

REVOKE ALL ON FUNCTION public.assign_guest_to_chair(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_guest_to_chair(uuid, uuid, text) TO authenticated;
