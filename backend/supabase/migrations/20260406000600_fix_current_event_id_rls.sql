-- Évite la récursion RLS profiles -> current_event_id() -> profiles.
-- La fonction s'exécute avec les droits de son propriétaire (postgres),
-- tout en restant limitée à l'utilisateur présent dans le JWT Supabase.
CREATE OR REPLACE FUNCTION public.current_event_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT event_id
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.current_event_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_event_id() TO authenticated;

-- Garantit qu'un utilisateur authentifié peut toujours charger son profil.
DROP POLICY IF EXISTS "profiles_own_read" ON public.profiles;
CREATE POLICY "profiles_own_read" ON public.profiles
  FOR SELECT TO authenticated
  USING (id = (SELECT auth.uid()));
