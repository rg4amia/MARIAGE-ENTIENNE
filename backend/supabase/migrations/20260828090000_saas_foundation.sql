-- ============================================================
-- Fondation SaaS multi-tenant pour l'organisation de mariages.
--
-- Cette migration est additive et conserve le contrat event_id actuel.
-- Elle introduit organization_id comme frontière commerciale et RLS,
-- puis ajoute les lieux, modèles de cartes et suivis d'envoi.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. TYPES MÉTIER
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'organization_role') THEN
    CREATE TYPE public.organization_role AS ENUM (
      'owner', 'admin', 'planner', 'coordinator', 'viewer'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'membership_status') THEN
    CREATE TYPE public.membership_status AS ENUM (
      'invited', 'active', 'suspended'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
    CREATE TYPE public.subscription_status AS ENUM (
      'trialing', 'active', 'past_due', 'canceled', 'suspended'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'venue_type') THEN
    CREATE TYPE public.venue_type AS ENUM (
      'town_hall', 'church', 'reception', 'other'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'seating_table_shape') THEN
    CREATE TYPE public.seating_table_shape AS ENUM (
      'round', 'rectangular', 'oval', 'u_shape', 'custom'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_channel') THEN
    CREATE TYPE public.delivery_channel AS ENUM (
      'whatsapp', 'email', 'sms', 'share_link', 'print'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'delivery_status') THEN
    CREATE TYPE public.delivery_status AS ENUM (
      'draft', 'queued', 'sent', 'delivered', 'failed', 'opened'
    );
  END IF;
END $$;

-- ============================================================
-- 2. FRONTIÈRE COMMERCIALE ET ABONNEMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.organizations (
  id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  slug           text        NOT NULL UNIQUE,
  name           text        NOT NULL CHECK (char_length(btrim(name)) >= 2),
  country_code   varchar(2)  NOT NULL DEFAULT 'CI'
                               CHECK (country_code = upper(country_code)),
  currency_code  varchar(3)  NOT NULL DEFAULT 'XOF'
                               CHECK (currency_code = upper(currency_code)),
  timezone       text        NOT NULL DEFAULT 'Africa/Abidjan',
  status         text        NOT NULL DEFAULT 'active'
                               CHECK (status IN ('active', 'suspended', 'closed')),
  logo_url       text,
  metadata       jsonb       NOT NULL DEFAULT '{}'::jsonb,
  created_at     timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at     timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.organization_memberships (
  organization_id uuid                       NOT NULL
    REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id          uuid                       NOT NULL
    REFERENCES auth.users(id) ON DELETE CASCADE,
  role             public.organization_role   NOT NULL DEFAULT 'planner',
  status           public.membership_status   NOT NULL DEFAULT 'invited',
  invited_by       uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  invited_at       timestamptz                NOT NULL DEFAULT timezone('utc', now()),
  accepted_at      timestamptz,
  created_at       timestamptz                NOT NULL DEFAULT timezone('utc', now()),
  updated_at       timestamptz                NOT NULL DEFAULT timezone('utc', now()),
  PRIMARY KEY (organization_id, user_id),
  CHECK (status <> 'active' OR accepted_at IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id                    text        PRIMARY KEY,
  name                  text        NOT NULL,
  description           text,
  amount_xof            bigint      NOT NULL DEFAULT 0 CHECK (amount_xof >= 0),
  billing_interval      text        NOT NULL DEFAULT 'month'
                                    CHECK (billing_interval IN ('month', 'year')),
  trial_days            integer     NOT NULL DEFAULT 0 CHECK (trial_days >= 0),
  max_events            integer     NOT NULL CHECK (max_events > 0),
  max_guests_per_event  integer     NOT NULL CHECK (max_guests_per_event > 0),
  max_storage_mb        integer     NOT NULL CHECK (max_storage_mb > 0),
  features              jsonb       NOT NULL DEFAULT '{}'::jsonb,
  is_active             boolean     NOT NULL DEFAULT true,
  sort_order            integer     NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at            timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.organization_subscriptions (
  id                    uuid                       PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       uuid                       NOT NULL UNIQUE
    REFERENCES public.organizations(id) ON DELETE CASCADE,
  plan_id               text                       NOT NULL
    REFERENCES public.subscription_plans(id) ON DELETE RESTRICT,
  status                public.subscription_status NOT NULL DEFAULT 'trialing',
  trial_ends_at         timestamptz,
  current_period_start  timestamptz                 NOT NULL DEFAULT timezone('utc', now()),
  current_period_end    timestamptz,
  canceled_at           timestamptz,
  provider              text,
  provider_customer_id  text,
  provider_reference    text,
  metadata              jsonb                       NOT NULL DEFAULT '{}'::jsonb,
  created_at            timestamptz                 NOT NULL DEFAULT timezone('utc', now()),
  updated_at            timestamptz                 NOT NULL DEFAULT timezone('utc', now()),
  CHECK (trial_ends_at IS NULL OR trial_ends_at >= current_period_start),
  CHECK (current_period_end IS NULL OR current_period_end >= current_period_start)
);

INSERT INTO public.subscription_plans (
  id, name, description, amount_xof, trial_days, max_events,
  max_guests_per_event, max_storage_mb, features, sort_order
) VALUES
  (
    'discovery', 'Découverte', 'Pour préparer un premier mariage',
    0, 0, 1, 100, 500,
    '{"invitation_templates": 1, "collaborators": 1, "custom_branding": false}'::jsonb,
    10
  ),
  (
    'pro', 'Pro', 'Pour les couples et wedding planners',
    25000, 14, 3, 500, 5120,
    '{"invitation_templates": 10, "collaborators": 5, "custom_branding": true}'::jsonb,
    20
  ),
  (
    'agency', 'Agence', 'Pour gérer plusieurs mariages en parallèle',
    75000, 14, 20, 2000, 20480,
    '{"invitation_templates": -1, "collaborators": 25, "custom_branding": true}'::jsonb,
    30
  )
ON CONFLICT (id) DO UPDATE SET
  name = excluded.name,
  description = excluded.description,
  amount_xof = excluded.amount_xof,
  trial_days = excluded.trial_days,
  max_events = excluded.max_events,
  max_guests_per_event = excluded.max_guests_per_event,
  max_storage_mb = excluded.max_storage_mb,
  features = excluded.features,
  sort_order = excluded.sort_order;

-- ============================================================
-- 3. RATTACHEMENT DES DONNÉES EXISTANTES
-- ============================================================

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS organization_id uuid;

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'planning'
  CHECK (status IN ('draft', 'planning', 'active', 'completed', 'archived', 'canceled'));

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS timezone text NOT NULL DEFAULT 'Africa/Abidjan';

ALTER TABLE public.wedding_events
  ADD COLUMN IF NOT EXISTS guest_count_estimate integer
  CHECK (guest_count_estimate IS NULL OR guest_count_estimate >= 0);

INSERT INTO public.organizations (slug, name)
SELECT e.slug, e.title
FROM public.wedding_events e
WHERE e.organization_id IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.organizations o WHERE o.slug = e.slug
  );

UPDATE public.wedding_events e
SET organization_id = o.id
FROM public.organizations o
WHERE e.organization_id IS NULL
  AND o.slug = e.slug;

ALTER TABLE public.wedding_events
  ALTER COLUMN organization_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'wedding_events_organization_id_fkey'
  ) THEN
    ALTER TABLE public.wedding_events
      ADD CONSTRAINT wedding_events_organization_id_fkey
      FOREIGN KEY (organization_id)
      REFERENCES public.organizations(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'wedding_events_id_organization_unique'
  ) THEN
    ALTER TABLE public.wedding_events
      ADD CONSTRAINT wedding_events_id_organization_unique
      UNIQUE (id, organization_id);
  END IF;
END $$;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS active_event_id uuid;

UPDATE public.profiles
SET active_event_id = event_id
WHERE active_event_id IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_active_event_id_fkey'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_active_event_id_fkey
      FOREIGN KEY (active_event_id)
      REFERENCES public.wedding_events(id) ON DELETE SET NULL;
  END IF;
END $$;

WITH ranked_profiles AS (
  SELECT
    e.organization_id,
    p.id AS user_id,
    row_number() OVER (
      PARTITION BY e.organization_id
      ORDER BY p.created_at, p.id
    ) AS member_rank
  FROM public.profiles p
  JOIN public.wedding_events e ON e.id = p.event_id
)
INSERT INTO public.organization_memberships (
  organization_id, user_id, role, status, accepted_at
)
SELECT
  organization_id,
  user_id,
  CASE WHEN member_rank = 1
    THEN 'owner'::public.organization_role
    ELSE 'planner'::public.organization_role
  END,
  'active'::public.membership_status,
  timezone('utc', now())
FROM ranked_profiles
ON CONFLICT (organization_id, user_id) DO NOTHING;

INSERT INTO public.organization_subscriptions (
  organization_id, plan_id, status, current_period_end
)
SELECT
  o.id,
  'discovery',
  'active'::public.subscription_status,
  timezone('utc', now()) + interval '100 years'
FROM public.organizations o
ON CONFLICT (organization_id) DO NOTHING;

-- ============================================================
-- 4. LIEUX, CARTOGRAPHIE ET PROGRAMME
-- ============================================================

CREATE TABLE IF NOT EXISTS public.event_venues (
  id                uuid              PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id          uuid              NOT NULL
    REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  venue_type        public.venue_type NOT NULL,
  name              text              NOT NULL CHECK (char_length(btrim(name)) >= 2),
  address_line      text,
  city              text,
  country_code      varchar(2)        NOT NULL DEFAULT 'CI'
                                      CHECK (country_code = upper(country_code)),
  latitude          numeric(9,6)      CHECK (latitude BETWEEN -90 AND 90),
  longitude         numeric(9,6)      CHECK (longitude BETWEEN -180 AND 180),
  place_provider    text              CHECK (
    place_provider IS NULL OR place_provider IN ('google', 'apple', 'openstreetmap', 'manual')
  ),
  place_id          text,
  maps_url          text,
  starts_at         timestamptz,
  ends_at           timestamptz,
  contact_name      text,
  contact_phone     text,
  instructions      text,
  sort_order        integer           NOT NULL DEFAULT 0,
  created_at        timestamptz       NOT NULL DEFAULT timezone('utc', now()),
  updated_at        timestamptz       NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (id, event_id),
  UNIQUE (event_id, venue_type, name),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at >= starts_at),
  CHECK (
    (latitude IS NULL AND longitude IS NULL)
    OR (latitude IS NOT NULL AND longitude IS NOT NULL)
  )
);

INSERT INTO public.event_venues (event_id, venue_type, name, sort_order)
SELECT e.id, seed.venue_type, seed.name, seed.sort_order
FROM public.wedding_events e
CROSS JOIN (
  VALUES
    ('town_hall'::public.venue_type, 'Mairie', 10),
    ('church'::public.venue_type, 'Église', 20),
    ('reception'::public.venue_type, 'Salle de réception', 30)
) AS seed(venue_type, name, sort_order)
ON CONFLICT (event_id, venue_type, name) DO NOTHING;

-- ============================================================
-- 5. CARTES D'INVITATION ET DIFFUSION
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invitation_templates (
  id                     uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id               uuid        NOT NULL
    REFERENCES public.wedding_events(id) ON DELETE CASCADE,
  name                   text        NOT NULL CHECK (char_length(btrim(name)) >= 2),
  template_key           text        NOT NULL,
  is_default             boolean     NOT NULL DEFAULT false,
  orientation            text        NOT NULL DEFAULT 'portrait'
                                      CHECK (orientation IN ('portrait', 'landscape', 'square')),
  palette                jsonb       NOT NULL DEFAULT '{}'::jsonb,
  typography             jsonb       NOT NULL DEFAULT '{}'::jsonb,
  content                jsonb       NOT NULL DEFAULT '{}'::jsonb,
  background_asset_path  text,
  preview_asset_path     text,
  created_at             timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at             timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (id, event_id),
  UNIQUE (event_id, template_key)
);

CREATE UNIQUE INDEX IF NOT EXISTS invitation_templates_one_default_per_event
  ON public.invitation_templates(event_id)
  WHERE is_default;

INSERT INTO public.invitation_templates (
  event_id, name, template_key, is_default, palette, typography, content
)
SELECT
  e.id,
  'Celestial Romance',
  'celestial-romance',
  true,
  '{"primary":"#A53C00","secondary":"#9C4236","accent":"#BE9A7A","background":"#FFF8F4"}'::jsonb,
  '{"heading":"Libre Caslon Text","body":"Plus Jakarta Sans"}'::jsonb,
  '{"show_venues":true,"show_table":true,"show_chair":true,"show_qr":true}'::jsonb
FROM public.wedding_events e
ON CONFLICT (event_id, template_key) DO NOTHING;

ALTER TABLE public.invitations
  ADD COLUMN IF NOT EXISTS invitation_template_id uuid;

ALTER TABLE public.invitations
  ADD COLUMN IF NOT EXISTS personalization jsonb NOT NULL DEFAULT '{}'::jsonb;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_template_event_fkey'
  ) THEN
    ALTER TABLE public.invitations
      ADD CONSTRAINT invitations_template_event_fkey
      FOREIGN KEY (invitation_template_id, event_id)
      REFERENCES public.invitation_templates(id, event_id)
      ON DELETE RESTRICT
      NOT VALID;
  END IF;
END $$;

UPDATE public.invitations i
SET invitation_template_id = t.id
FROM public.invitation_templates t
WHERE i.event_id = t.event_id
  AND t.is_default
  AND i.invitation_template_id IS NULL;

ALTER TABLE public.invitations
  VALIDATE CONSTRAINT invitations_template_event_fkey;

CREATE TABLE IF NOT EXISTS public.invitation_deliveries (
  id                   uuid                     PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id             uuid                     NOT NULL,
  invitation_id        uuid                     NOT NULL,
  channel              public.delivery_channel  NOT NULL,
  status               public.delivery_status   NOT NULL DEFAULT 'draft',
  recipient_name       text,
  destination          text,
  provider             text,
  provider_message_id  text,
  error_message        text,
  queued_at            timestamptz,
  sent_at              timestamptz,
  delivered_at         timestamptz,
  opened_at            timestamptz,
  created_by           uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at           timestamptz              NOT NULL DEFAULT timezone('utc', now()),
  updated_at           timestamptz              NOT NULL DEFAULT timezone('utc', now()),
  FOREIGN KEY (invitation_id) REFERENCES public.invitations(id) ON DELETE CASCADE,
  CHECK (delivered_at IS NULL OR sent_at IS NULL OR delivered_at >= sent_at),
  CHECK (opened_at IS NULL OR sent_at IS NULL OR opened_at >= sent_at)
);

-- ============================================================
-- 6. PLAN DE SALLE ENRICHI ET COHÉRENCE INTER-ÉVÉNEMENT
-- ============================================================

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS venue_id uuid;

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS shape public.seating_table_shape NOT NULL DEFAULT 'round';

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS zone_label text;

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS position_x numeric(10,3);

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS position_y numeric(10,3);

ALTER TABLE public.seating_tables
  ADD COLUMN IF NOT EXISTS rotation_degrees numeric(6,2) NOT NULL DEFAULT 0
  CHECK (rotation_degrees >= 0 AND rotation_degrees < 360);

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS seat_label text;

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS position_x numeric(10,3);

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS position_y numeric(10,3);

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS rotation_degrees numeric(6,2) NOT NULL DEFAULT 0
  CHECK (rotation_degrees >= 0 AND rotation_degrees < 360);

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS is_accessible boolean NOT NULL DEFAULT false;

ALTER TABLE public.chairs
  ADD COLUMN IF NOT EXISTS notes text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'seating_tables_id_event_unique'
  ) THEN
    ALTER TABLE public.seating_tables
      ADD CONSTRAINT seating_tables_id_event_unique UNIQUE (id, event_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'guests_id_event_unique'
  ) THEN
    ALTER TABLE public.guests
      ADD CONSTRAINT guests_id_event_unique UNIQUE (id, event_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chairs_id_event_unique'
  ) THEN
    ALTER TABLE public.chairs
      ADD CONSTRAINT chairs_id_event_unique UNIQUE (id, event_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_id_event_unique'
  ) THEN
    ALTER TABLE public.invitations
      ADD CONSTRAINT invitations_id_event_unique UNIQUE (id, event_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'seating_tables_venue_event_fkey'
  ) THEN
    ALTER TABLE public.seating_tables
      ADD CONSTRAINT seating_tables_venue_event_fkey
      FOREIGN KEY (venue_id, event_id)
      REFERENCES public.event_venues(id, event_id)
      ON DELETE RESTRICT
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chairs_table_event_fkey'
  ) THEN
    ALTER TABLE public.chairs
      ADD CONSTRAINT chairs_table_event_fkey
      FOREIGN KEY (table_id, event_id)
      REFERENCES public.seating_tables(id, event_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chairs_guest_event_fkey'
  ) THEN
    ALTER TABLE public.chairs
      ADD CONSTRAINT chairs_guest_event_fkey
      FOREIGN KEY (guest_id, event_id)
      REFERENCES public.guests(id, event_id)
      ON DELETE NO ACTION
      DEFERRABLE INITIALLY DEFERRED
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitation_deliveries_invitation_event_fkey'
  ) THEN
    ALTER TABLE public.invitation_deliveries
      ADD CONSTRAINT invitation_deliveries_invitation_event_fkey
      FOREIGN KEY (invitation_id, event_id)
      REFERENCES public.invitations(id, event_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_guest_event_fkey'
  ) THEN
    ALTER TABLE public.invitations
      ADD CONSTRAINT invitations_guest_event_fkey
      FOREIGN KEY (guest_id, event_id)
      REFERENCES public.guests(id, event_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_table_event_fkey'
  ) THEN
    ALTER TABLE public.invitations
      ADD CONSTRAINT invitations_table_event_fkey
      FOREIGN KEY (table_id, event_id)
      REFERENCES public.seating_tables(id, event_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'invitations_chair_event_fkey'
  ) THEN
    ALTER TABLE public.invitations
      ADD CONSTRAINT invitations_chair_event_fkey
      FOREIGN KEY (chair_id, event_id)
      REFERENCES public.chairs(id, event_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END $$;

ALTER TABLE public.seating_tables VALIDATE CONSTRAINT seating_tables_venue_event_fkey;
ALTER TABLE public.chairs VALIDATE CONSTRAINT chairs_table_event_fkey;
ALTER TABLE public.chairs VALIDATE CONSTRAINT chairs_guest_event_fkey;
ALTER TABLE public.invitation_deliveries
  VALIDATE CONSTRAINT invitation_deliveries_invitation_event_fkey;
ALTER TABLE public.invitations VALIDATE CONSTRAINT invitations_guest_event_fkey;
ALTER TABLE public.invitations VALIDATE CONSTRAINT invitations_table_event_fkey;
ALTER TABLE public.invitations VALIDATE CONSTRAINT invitations_chair_event_fkey;

CREATE INDEX IF NOT EXISTS idx_wedding_events_organization_id
  ON public.wedding_events(organization_id);
CREATE INDEX IF NOT EXISTS idx_memberships_user_id
  ON public.organization_memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_event_venues_event_id
  ON public.event_venues(event_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_invitation_templates_event_id
  ON public.invitation_templates(event_id);
CREATE INDEX IF NOT EXISTS idx_invitation_deliveries_event_id
  ON public.invitation_deliveries(event_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_invitation_deliveries_invitation_id
  ON public.invitation_deliveries(invitation_id);

-- ============================================================
-- 7. FONCTIONS D'AUTORISATION ET ONBOARDING
-- ============================================================

CREATE OR REPLACE FUNCTION public.saas_slug(p_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = public
AS $$
  SELECT trim(
    both '-' FROM regexp_replace(lower(btrim(p_value)), '[^a-z0-9]+', '-', 'g')
  );
$$;

CREATE OR REPLACE FUNCTION public.current_event_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(active_event_id, event_id)
  FROM public.profiles
  WHERE id = (SELECT auth.uid())
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_organization_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT e.organization_id
  FROM public.wedding_events e
  WHERE e.id = public.current_event_id()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.has_organization_role(
  p_organization_id uuid,
  p_roles public.organization_role[] DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.organization_memberships m
    WHERE m.organization_id = p_organization_id
      AND m.user_id = (SELECT auth.uid())
      AND m.status = 'active'
      AND (p_roles IS NULL OR m.role = ANY(p_roles))
  );
$$;

CREATE OR REPLACE FUNCTION public.is_event_member(p_event_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.wedding_events e
    JOIN public.organization_memberships m
      ON m.organization_id = e.organization_id
    WHERE e.id = p_event_id
      AND m.user_id = (SELECT auth.uid())
      AND m.status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_event(p_event_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.wedding_events e
    JOIN public.organization_memberships m
      ON m.organization_id = e.organization_id
    WHERE e.id = p_event_id
      AND m.user_id = (SELECT auth.uid())
      AND m.status = 'active'
      AND m.role IN ('owner', 'admin', 'planner', 'coordinator')
  );
$$;

-- Remplace le rôle JWT global par l'appartenance réelle à l'organisation.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.can_manage_event(public.current_event_id());
$$;

CREATE OR REPLACE FUNCTION public.switch_active_event(p_event_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_event_member(p_event_id) THEN
    RAISE EXCEPTION 'Wedding event not found or access denied';
  END IF;

  UPDATE public.profiles
  SET active_event_id = p_event_id,
      event_id = p_event_id,
      updated_at = timezone('utc', now())
  WHERE id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  RETURN p_event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_saas_workspace(
  p_organization_name text,
  p_event_title text,
  p_bride_name text,
  p_groom_name text,
  p_event_date timestamptz DEFAULT NULL,
  p_country_code varchar(2) DEFAULT 'CI',
  p_timezone text DEFAULT 'Africa/Abidjan'
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_organization public.organizations;
  v_event public.wedding_events;
  v_plan public.subscription_plans;
  v_base_slug text;
  v_full_name text;
  v_phone text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.organization_memberships
    WHERE user_id = v_user_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'The current user already belongs to an organization';
  END IF;
  IF nullif(btrim(p_organization_name), '') IS NULL THEN
    RAISE EXCEPTION 'Organization name is required';
  END IF;
  IF nullif(btrim(p_event_title), '') IS NULL
     OR nullif(btrim(p_bride_name), '') IS NULL
     OR nullif(btrim(p_groom_name), '') IS NULL THEN
    RAISE EXCEPTION 'Wedding title and couple names are required';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = 'pro' AND is_active;
  IF v_plan.id IS NULL THEN
    RAISE EXCEPTION 'Default SaaS plan is unavailable';
  END IF;

  v_base_slug := public.saas_slug(p_organization_name);
  IF v_base_slug = '' THEN v_base_slug := 'organisation'; END IF;

  SELECT
    coalesce(
      nullif(raw_user_meta_data ->> 'full_name', ''),
      split_part(email, '@', 1),
      'Organisateur'
    ),
    nullif(raw_user_meta_data ->> 'phone', '')
  INTO v_full_name, v_phone
  FROM auth.users
  WHERE id = v_user_id;

  INSERT INTO public.organizations (
    slug, name, country_code, currency_code, timezone
  ) VALUES (
    v_base_slug || '-' || encode(gen_random_bytes(3), 'hex'),
    btrim(p_organization_name),
    upper(coalesce(nullif(btrim(p_country_code), ''), 'CI')),
    'XOF',
    coalesce(nullif(btrim(p_timezone), ''), 'Africa/Abidjan')
  ) RETURNING * INTO v_organization;

  INSERT INTO public.organization_memberships (
    organization_id, user_id, role, status, accepted_at
  ) VALUES (
    v_organization.id,
    v_user_id,
    'owner',
    'active',
    timezone('utc', now())
  );

  INSERT INTO public.organization_subscriptions (
    organization_id, plan_id, status, trial_ends_at, current_period_end
  ) VALUES (
    v_organization.id,
    v_plan.id,
    'trialing',
    timezone('utc', now()) + make_interval(days => v_plan.trial_days),
    timezone('utc', now()) + make_interval(days => v_plan.trial_days)
  );

  INSERT INTO public.wedding_events (
    organization_id, slug, title, bride_name, groom_name,
    event_date, timezone, status
  ) VALUES (
    v_organization.id,
    public.saas_slug(p_event_title) || '-' || encode(gen_random_bytes(3), 'hex'),
    btrim(p_event_title),
    btrim(p_bride_name),
    btrim(p_groom_name),
    p_event_date,
    v_organization.timezone,
    'planning'
  ) RETURNING * INTO v_event;

  INSERT INTO public.profiles (
    id, event_id, active_event_id, role, full_name, phone
  ) VALUES (
    v_user_id, v_event.id, v_event.id, 'admin', v_full_name, v_phone
  )
  ON CONFLICT (id) DO UPDATE SET
    event_id = excluded.event_id,
    active_event_id = excluded.active_event_id,
    full_name = coalesce(nullif(public.profiles.full_name, ''), excluded.full_name),
    phone = coalesce(public.profiles.phone, excluded.phone),
    updated_at = timezone('utc', now());

  INSERT INTO public.event_venues (event_id, venue_type, name, sort_order)
  VALUES
    (v_event.id, 'town_hall', 'Mairie', 10),
    (v_event.id, 'church', 'Église', 20),
    (v_event.id, 'reception', 'Salle de réception', 30);

  INSERT INTO public.invitation_templates (
    event_id, name, template_key, is_default, palette, typography, content
  ) VALUES (
    v_event.id,
    'Celestial Romance',
    'celestial-romance',
    true,
    '{"primary":"#A53C00","secondary":"#9C4236","accent":"#BE9A7A","background":"#FFF8F4"}'::jsonb,
    '{"heading":"Libre Caslon Text","body":"Plus Jakarta Sans"}'::jsonb,
    '{"show_venues":true,"show_table":true,"show_chair":true,"show_qr":true}'::jsonb
  );

  RETURN jsonb_build_object(
    'organization_id', v_organization.id,
    'organization_name', v_organization.name,
    'event_id', v_event.id,
    'event_title', v_event.title,
    'plan_id', v_plan.id,
    'trial_ends_at', timezone('utc', now()) + make_interval(days => v_plan.trial_days)
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.create_wedding_event(
  p_event_title text,
  p_bride_name text,
  p_groom_name text,
  p_event_date timestamptz DEFAULT NULL,
  p_make_active boolean DEFAULT true
)
RETURNS public.wedding_events
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_organization_id uuid := public.current_organization_id();
  v_event public.wedding_events;
  v_max_events integer;
  v_event_count integer;
BEGIN
  IF v_organization_id IS NULL OR NOT public.has_organization_role(
    v_organization_id,
    ARRAY['owner', 'admin', 'planner']::public.organization_role[]
  ) THEN
    RAISE EXCEPTION 'Organization manager role required';
  END IF;

  SELECT p.max_events INTO v_max_events
  FROM public.organization_subscriptions s
  JOIN public.subscription_plans p ON p.id = s.plan_id
  WHERE s.organization_id = v_organization_id
    AND s.status IN ('trialing', 'active');
  IF v_max_events IS NULL THEN
    RAISE EXCEPTION 'An active subscription is required';
  END IF;

  SELECT count(*) INTO v_event_count
  FROM public.wedding_events
  WHERE organization_id = v_organization_id
    AND status <> 'archived';
  IF v_event_count >= v_max_events THEN
    RAISE EXCEPTION 'Wedding event limit reached for the current plan';
  END IF;

  INSERT INTO public.wedding_events (
    organization_id, slug, title, bride_name, groom_name,
    event_date, timezone, status
  )
  SELECT
    o.id,
    public.saas_slug(p_event_title) || '-' || encode(gen_random_bytes(3), 'hex'),
    btrim(p_event_title),
    btrim(p_bride_name),
    btrim(p_groom_name),
    p_event_date,
    o.timezone,
    'planning'
  FROM public.organizations o
  WHERE o.id = v_organization_id
  RETURNING * INTO v_event;

  INSERT INTO public.event_venues (event_id, venue_type, name, sort_order)
  VALUES
    (v_event.id, 'town_hall', 'Mairie', 10),
    (v_event.id, 'church', 'Église', 20),
    (v_event.id, 'reception', 'Salle de réception', 30);

  INSERT INTO public.invitation_templates (
    event_id, name, template_key, is_default, palette, typography, content
  ) VALUES (
    v_event.id,
    'Celestial Romance',
    'celestial-romance',
    true,
    '{"primary":"#A53C00","secondary":"#9C4236","accent":"#BE9A7A","background":"#FFF8F4"}'::jsonb,
    '{"heading":"Libre Caslon Text","body":"Plus Jakarta Sans"}'::jsonb,
    '{"show_venues":true,"show_table":true,"show_chair":true,"show_qr":true}'::jsonb
  );

  IF p_make_active THEN
    PERFORM public.switch_active_event(v_event.id);
  END IF;

  RETURN v_event;
END;
$$;

-- Les nouveaux comptes ne doivent plus pouvoir choisir un event_id arbitraire
-- dans user_metadata. Le workspace est créé par create_saas_workspace().
CREATE OR REPLACE FUNCTION public.handle_new_user_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || '{"role":"admin"}'::jsonb
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_last_organization_owner()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.role = 'owner'
     AND OLD.status = 'active'
     AND (
       TG_OP = 'DELETE'
       OR NEW.role <> 'owner'
       OR NEW.status <> 'active'
     )
     AND NOT EXISTS (
       SELECT 1
       FROM public.organization_memberships m
       WHERE m.organization_id = OLD.organization_id
         AND m.user_id <> OLD.user_id
         AND m.role = 'owner'
         AND m.status = 'active'
     ) THEN
    RAISE EXCEPTION 'An organization must keep at least one active owner';
  END IF;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

REVOKE ALL ON FUNCTION public.saas_slug(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.current_event_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.current_organization_id() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.has_organization_role(uuid, public.organization_role[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_event_member(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_manage_event(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.switch_active_event(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_saas_workspace(
  text, text, text, text, timestamptz, varchar, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_wedding_event(
  text, text, text, timestamptz, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.protect_last_organization_owner() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.current_event_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_organization_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_organization_role(uuid, public.organization_role[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_event_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_manage_event(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.switch_active_event(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_saas_workspace(
  text, text, text, text, timestamptz, varchar, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_wedding_event(
  text, text, text, timestamptz, boolean
) TO authenticated;

-- ============================================================
-- 8. TRIGGERS, RLS ET PRIVILÈGES
-- ============================================================

DROP TRIGGER IF EXISTS trg_organizations_updated_at ON public.organizations;
CREATE TRIGGER trg_organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_memberships_updated_at ON public.organization_memberships;
CREATE TRIGGER trg_memberships_updated_at
  BEFORE UPDATE ON public.organization_memberships
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_protect_last_organization_owner
  ON public.organization_memberships;
CREATE TRIGGER trg_protect_last_organization_owner
  BEFORE UPDATE OR DELETE ON public.organization_memberships
  FOR EACH ROW EXECUTE FUNCTION public.protect_last_organization_owner();

DROP TRIGGER IF EXISTS trg_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER trg_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_organization_subscriptions_updated_at
  ON public.organization_subscriptions;
CREATE TRIGGER trg_organization_subscriptions_updated_at
  BEFORE UPDATE ON public.organization_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_event_venues_updated_at ON public.event_venues;
CREATE TRIGGER trg_event_venues_updated_at
  BEFORE UPDATE ON public.event_venues
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_invitation_templates_updated_at
  ON public.invitation_templates;
CREATE TRIGGER trg_invitation_templates_updated_at
  BEFORE UPDATE ON public.invitation_templates
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_invitation_deliveries_updated_at
  ON public.invitation_deliveries;
CREATE TRIGGER trg_invitation_deliveries_updated_at
  BEFORE UPDATE ON public.invitation_deliveries
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitation_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitation_deliveries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "organizations_member_select" ON public.organizations
  FOR SELECT TO authenticated
  USING (public.has_organization_role(id));

CREATE POLICY "organizations_manager_update" ON public.organizations
  FOR UPDATE TO authenticated
  USING (public.has_organization_role(
    id, ARRAY['owner', 'admin']::public.organization_role[]
  ))
  WITH CHECK (public.has_organization_role(
    id, ARRAY['owner', 'admin']::public.organization_role[]
  ));

CREATE POLICY "memberships_own_select" ON public.organization_memberships
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY "memberships_manager_all" ON public.organization_memberships
  FOR ALL TO authenticated
  USING (public.has_organization_role(
    organization_id, ARRAY['owner', 'admin']::public.organization_role[]
  ))
  WITH CHECK (public.has_organization_role(
    organization_id, ARRAY['owner', 'admin']::public.organization_role[]
  ));

CREATE POLICY "subscription_plans_public_select" ON public.subscription_plans
  FOR SELECT TO anon, authenticated
  USING (is_active);

CREATE POLICY "subscriptions_manager_select" ON public.organization_subscriptions
  FOR SELECT TO authenticated
  USING (public.has_organization_role(
    organization_id, ARRAY['owner', 'admin']::public.organization_role[]
  ));

CREATE POLICY "wedding_events_organization_select" ON public.wedding_events
  FOR SELECT TO authenticated
  USING (public.has_organization_role(organization_id));

CREATE POLICY "wedding_events_manager_update" ON public.wedding_events
  FOR UPDATE TO authenticated
  USING (public.can_manage_event(id))
  WITH CHECK (public.can_manage_event(id));

CREATE POLICY "event_venues_member_select" ON public.event_venues
  FOR SELECT TO authenticated
  USING (public.is_event_member(event_id));

CREATE POLICY "event_venues_manager_all" ON public.event_venues
  FOR ALL TO authenticated
  USING (public.can_manage_event(event_id))
  WITH CHECK (public.can_manage_event(event_id));

CREATE POLICY "invitation_templates_member_select" ON public.invitation_templates
  FOR SELECT TO authenticated
  USING (public.is_event_member(event_id));

CREATE POLICY "invitation_templates_manager_all" ON public.invitation_templates
  FOR ALL TO authenticated
  USING (public.can_manage_event(event_id))
  WITH CHECK (public.can_manage_event(event_id));

CREATE POLICY "invitation_deliveries_member_select" ON public.invitation_deliveries
  FOR SELECT TO authenticated
  USING (public.is_event_member(event_id));

CREATE POLICY "invitation_deliveries_manager_all" ON public.invitation_deliveries
  FOR ALL TO authenticated
  USING (public.can_manage_event(event_id))
  WITH CHECK (public.can_manage_event(event_id));

REVOKE ALL ON public.organizations FROM anon;
REVOKE ALL ON public.organization_memberships FROM anon;
REVOKE ALL ON public.organization_subscriptions FROM anon;
REVOKE ALL ON public.event_venues FROM anon;
REVOKE ALL ON public.invitation_templates FROM anon;
REVOKE ALL ON public.invitation_deliveries FROM anon;

GRANT SELECT, UPDATE ON public.organizations TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.organization_memberships TO authenticated;
GRANT SELECT ON public.subscription_plans TO anon, authenticated;
GRANT SELECT ON public.organization_subscriptions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_venues TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitation_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitation_deliveries TO authenticated;
