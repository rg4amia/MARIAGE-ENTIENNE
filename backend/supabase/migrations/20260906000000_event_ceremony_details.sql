-- Lieux et horaires de la cérémonie religieuse et de la réception, paramétrables
-- par le couple (ils étaient figés dans le message d'invitation). Les heures
-- sont stockées en texte « HH:MM » ; NULL = valeurs par défaut de l'application.

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS ceremony_venue text,
  ADD COLUMN IF NOT EXISTS ceremony_time text,
  ADD COLUMN IF NOT EXISTS reception_venue text,
  ADD COLUMN IF NOT EXISTS reception_time text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'wedding_events_ceremony_times_check'
      AND conrelid = 'public.wedding_events'::regclass
  ) THEN
    ALTER TABLE public.wedding_events
      ADD CONSTRAINT wedding_events_ceremony_times_check
      CHECK (
        (ceremony_time IS NULL OR ceremony_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
        AND (reception_time IS NULL OR reception_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
      );
  END IF;
END $$;
