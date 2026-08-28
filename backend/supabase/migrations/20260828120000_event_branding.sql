-- Identité visuelle partagée par mariage.
-- La palette est isolée par event_id et réutilisée par l'application ainsi que
-- par le modèle d'invitation par défaut.

CREATE TABLE IF NOT EXISTS public.event_branding (
  event_id         uuid        PRIMARY KEY
    REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  primary_color    varchar(7)  NOT NULL DEFAULT '#A53C00',
  secondary_color  varchar(7)  NOT NULL DEFAULT '#9C4236',
  accent_color     varchar(7)  NOT NULL DEFAULT '#BE9A7A',
  background_color varchar(7)  NOT NULL DEFAULT '#FFF8F4',
  updated_by       uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT event_branding_primary_hex
    CHECK (primary_color ~ '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT event_branding_secondary_hex
    CHECK (secondary_color ~ '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT event_branding_accent_hex
    CHECK (accent_color ~ '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT event_branding_background_hex
    CHECK (background_color ~ '^#[0-9A-Fa-f]{6}$')
);

INSERT INTO public.event_branding (
  event_id, primary_color, secondary_color, accent_color, background_color
)
SELECT
  e.id,
  CASE WHEN t.palette ->> 'primary' ~ '^#[0-9A-Fa-f]{6}$'
    THEN upper(t.palette ->> 'primary') ELSE '#A53C00' END,
  CASE WHEN t.palette ->> 'secondary' ~ '^#[0-9A-Fa-f]{6}$'
    THEN upper(t.palette ->> 'secondary') ELSE '#9C4236' END,
  CASE WHEN t.palette ->> 'accent' ~ '^#[0-9A-Fa-f]{6}$'
    THEN upper(t.palette ->> 'accent') ELSE '#BE9A7A' END,
  CASE WHEN t.palette ->> 'background' ~ '^#[0-9A-Fa-f]{6}$'
    THEN upper(t.palette ->> 'background') ELSE '#FFF8F4' END
FROM public.wedding_events e
LEFT JOIN public.invitation_templates t
  ON t.event_id = e.id AND t.is_default
ON CONFLICT (event_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.create_default_event_branding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.event_branding (event_id)
  VALUES (NEW.id)
  ON CONFLICT (event_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_create_default_event_branding
  ON public.wedding_events;
CREATE TRIGGER trg_create_default_event_branding
AFTER INSERT ON public.wedding_events
FOR EACH ROW EXECUTE FUNCTION public.create_default_event_branding();

CREATE OR REPLACE FUNCTION public.sync_event_branding()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.primary_color := upper(NEW.primary_color);
  NEW.secondary_color := upper(NEW.secondary_color);
  NEW.accent_color := upper(NEW.accent_color);
  NEW.background_color := upper(NEW.background_color);
  NEW.updated_by := auth.uid();
  NEW.updated_at := timezone('utc', now());
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_event_branding
  ON public.event_branding;
CREATE TRIGGER trg_sync_event_branding
BEFORE UPDATE ON public.event_branding
FOR EACH ROW EXECUTE FUNCTION public.sync_event_branding();

CREATE OR REPLACE FUNCTION public.sync_default_invitation_palette()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.invitation_templates
  SET palette = palette || jsonb_build_object(
        'primary', NEW.primary_color,
        'secondary', NEW.secondary_color,
        'accent', NEW.accent_color,
        'background', NEW.background_color
      ),
      updated_at = timezone('utc', now())
  WHERE event_id = NEW.event_id
    AND is_default;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_default_invitation_palette
  ON public.event_branding;
CREATE TRIGGER trg_sync_default_invitation_palette
AFTER UPDATE OF primary_color, secondary_color, accent_color, background_color
ON public.event_branding
FOR EACH ROW EXECUTE FUNCTION public.sync_default_invitation_palette();

ALTER TABLE public.event_branding ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "event_branding_member_select"
  ON public.event_branding;
CREATE POLICY "event_branding_member_select" ON public.event_branding
  FOR SELECT TO authenticated
  USING (public.is_event_member(event_id));

DROP POLICY IF EXISTS "event_branding_manager_update"
  ON public.event_branding;
CREATE POLICY "event_branding_manager_update" ON public.event_branding
  FOR UPDATE TO authenticated
  USING (public.can_manage_event(event_id))
  WITH CHECK (public.can_manage_event(event_id));

REVOKE ALL ON public.event_branding FROM PUBLIC, anon;
GRANT SELECT, UPDATE ON public.event_branding TO authenticated;

REVOKE ALL ON FUNCTION public.create_default_event_branding() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_event_branding() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sync_default_invitation_palette() FROM PUBLIC;
