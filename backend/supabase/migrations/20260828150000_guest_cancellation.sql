-- Annulation réversible d'un invité : on conserve ses données et son historique,
-- mais on bloque l'accès invité et on libère sa place.
ALTER TYPE public.invitation_status ADD VALUE IF NOT EXISTS 'cancelled';

ALTER TABLE public.guests
  ADD COLUMN IF NOT EXISTS cancelled_at timestamptz,
  ADD COLUMN IF NOT EXISTS status_before_cancellation public.invitation_status;
