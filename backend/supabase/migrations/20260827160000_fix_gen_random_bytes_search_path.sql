-- Fix: gen_random_bytes(integer) does not exist (code 42883)
-- Root cause: on hosted Supabase projects, pgcrypto installs its functions
-- into the "extensions" schema, not "public". assign_guest_to_chair() sets
-- search_path = public only, so the unqualified call to gen_random_bytes()
-- cannot resolve even though the extension is enabled.

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

ALTER FUNCTION public.assign_guest_to_chair(uuid, uuid, text)
  SET search_path = public, extensions;
