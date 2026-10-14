-- Corrige les noms du couple pour l'événement de production.
-- Ce script est idempotent : il peut être rejoué sans effet si les données
-- sont déjà correctes.
UPDATE public.wedding_events
SET
  title      = 'Mariage Kodjo et Marie Ange',
  bride_name = 'Tiemele Marie Ange',
  groom_name = 'Mawule Kodjo',
  slug       = 'mariage-kodjo-marie-ange',
  updated_at = timezone('utc', now())
WHERE id = '00000000-0000-0000-0000-000000000001';
