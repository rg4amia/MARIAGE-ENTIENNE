-- Typographie du mariage.
-- Les mariés choisissent une police de titres (prénoms, grands titres, carte
-- d'invitation) et une police de texte lisible pour le reste de l'application.
-- Les listes autorisées reflètent WeddingFonts côté application.

ALTER TABLE public.event_branding
  ADD COLUMN IF NOT EXISTS display_font text NOT NULL
    DEFAULT 'Plus Jakarta Sans',
  ADD COLUMN IF NOT EXISTS body_font text NOT NULL
    DEFAULT 'Plus Jakarta Sans';

ALTER TABLE public.event_branding
  DROP CONSTRAINT IF EXISTS event_branding_display_font_allowed;
ALTER TABLE public.event_branding
  ADD CONSTRAINT event_branding_display_font_allowed CHECK (
    display_font IN (
      'Plus Jakarta Sans',
      'Playfair Display',
      'Cormorant Garamond',
      'Marcellus',
      'Italiana',
      'Great Vibes',
      'Dancing Script'
    )
  );

ALTER TABLE public.event_branding
  DROP CONSTRAINT IF EXISTS event_branding_body_font_allowed;
ALTER TABLE public.event_branding
  ADD CONSTRAINT event_branding_body_font_allowed CHECK (
    body_font IN (
      'Plus Jakarta Sans',
      'Lora',
      'Montserrat',
      'Raleway',
      'Nunito Sans',
      'Work Sans'
    )
  );

-- Le portail invité public lit `invitation_templates.palette` : on y propage
-- aussi les polices pour que la carte web corresponde à l'application.
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
        'background', NEW.background_color,
        'display_font', NEW.display_font,
        'body_font', NEW.body_font
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
AFTER UPDATE OF primary_color, secondary_color, accent_color,
                background_color, display_font, body_font
ON public.event_branding
FOR EACH ROW EXECUTE FUNCTION public.sync_default_invitation_palette();

REVOKE ALL ON FUNCTION public.sync_default_invitation_palette() FROM PUBLIC;
