-- Fix: gen_random_bytes(integer) does not exist dans create_saas_workspace
--
-- Sur Supabase hébergé, pgcrypto s'installe dans le schéma "extensions".
-- create_saas_workspace utilise SET search_path = public uniquement, ce qui
-- empêche la résolution de gen_random_bytes() et encode() lors de la
-- génération des slugs aléatoires.
-- La même correction avait déjà été appliquée à assign_guest_to_chair dans
-- 20260827160000_fix_gen_random_bytes_search_path.sql.

ALTER FUNCTION public.create_saas_workspace(
  text, text, text, text, timestamptz, varchar(2), text
)
SET search_path = public, extensions;
