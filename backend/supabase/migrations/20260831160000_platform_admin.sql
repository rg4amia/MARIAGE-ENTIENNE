-- Super-administrateur de la plateforme.
--
-- À ne pas confondre avec `is_admin()`, qui désigne l'organisateur d'un
-- mariage. Il s'agit ici de l'exploitant du service : celui qui voit tous
-- les comptes, tous les mariages, et qui peut faire un geste commercial.
--
-- Deux principes :
--   * l'appartenance ne s'accorde pas depuis l'application. Aucune
--     politique n'autorise l'écriture sur `platform_admins` : seul
--     `service_role` (ou un accès SQL direct) peut nommer un administrateur.
--   * la console ne perce pas les politiques RLS existantes. Elle passe par
--     des fonctions `security definer` qui vérifient la qualité d'admin puis
--     renvoient un agrégat — plutôt que d'ouvrir chaque table à un rôle
--     privilégié, ce qui se serait payé à la première policy oubliée.

create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  note text,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.platform_admins is
  'Exploitants du service. Se peuple hors application (service_role ou SQL).';

alter table public.platform_admins enable row level security;

-- Un administrateur peut vérifier qu'il en est un ; personne ne peut écrire.
drop policy if exists platform_admins_self_select on public.platform_admins;
create policy platform_admins_self_select
  on public.platform_admins
  for select
  to authenticated
  using (user_id = auth.uid());

revoke insert, update, delete on public.platform_admins
  from anon, authenticated;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins
    where user_id = auth.uid()
  );
$$;

comment on function public.is_platform_admin() is
  'Vrai si l''utilisateur courant exploite la plateforme.';

revoke all on function public.is_platform_admin() from public, anon;
grant execute on function public.is_platform_admin() to authenticated;

-- ---------------------------------------------------------------------------
-- Journal : un pouvoir aussi large ne s'exerce pas sans trace.
-- ---------------------------------------------------------------------------
create table if not exists public.platform_admin_audit (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users (id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.platform_admin_audit is
  'Trace des gestes d''exploitation : changement de forfait, suspension, crédit.';

create index if not exists idx_platform_admin_audit_created
  on public.platform_admin_audit (created_at desc);

alter table public.platform_admin_audit enable row level security;

drop policy if exists platform_admin_audit_admin_select
  on public.platform_admin_audit;
create policy platform_admin_audit_admin_select
  on public.platform_admin_audit
  for select
  to authenticated
  using (public.is_platform_admin());

revoke insert, update, delete on public.platform_admin_audit
  from anon, authenticated;

create or replace function public.log_platform_admin_action(
  p_action text,
  p_target_type text,
  p_target_id uuid,
  p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.platform_admin_audit (
    actor_id, action, target_type, target_id, details
  ) values (auth.uid(), p_action, p_target_type, p_target_id, p_details);
$$;

revoke all on function public.log_platform_admin_action(text, text, uuid, jsonb)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Geste commercial : créditer des envois sans toucher au registre, qui doit
-- rester monotone. On relève la limite, on n'efface pas la consommation.
-- ---------------------------------------------------------------------------
create table if not exists public.invitation_quota_grants (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events (id) on delete cascade,
  extra_invitations integer not null check (extra_invitations > 0),
  reason text not null,
  granted_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now())
);

comment on table public.invitation_quota_grants is
  'Envois offerts par l''exploitant. S''ajoutent à la limite du forfait.';

create index if not exists idx_invitation_quota_grants_event
  on public.invitation_quota_grants (event_id);

alter table public.invitation_quota_grants enable row level security;

drop policy if exists invitation_quota_grants_member_select
  on public.invitation_quota_grants;
create policy invitation_quota_grants_member_select
  on public.invitation_quota_grants
  for select
  to authenticated
  using (public.is_event_member(event_id) or public.is_platform_admin());

revoke insert, update, delete on public.invitation_quota_grants
  from anon, authenticated;

-- La limite effective inclut les envois offerts. Un forfait illimité le reste.
create or replace function public.event_plan_limits(p_event_id uuid)
returns table (
  plan_id text,
  plan_name text,
  max_guests_per_event integer,
  max_invitations integer,
  collaborators integer,
  status public.subscription_status
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.name,
    p.max_guests_per_event,
    case
      when p.max_invitations = -1 then -1
      else p.max_invitations + coalesce((
        select sum(g.extra_invitations)::integer
        from public.invitation_quota_grants g
        where g.event_id = e.id
      ), 0)
    end,
    coalesce((p.features ->> 'collaborators')::integer, -1),
    public.effective_subscription_status(s.status, s.trial_ends_at)
  from public.wedding_events e
  join public.organization_subscriptions s
    on s.organization_id = e.organization_id
  join public.subscription_plans p on p.id = s.plan_id
  where e.id = p_event_id;
$$;

-- ---------------------------------------------------------------------------
-- Console : lectures agrégées.
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_organizations(
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
DECLARE
  v_rows jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  SELECT coalesce(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.created_at DESC), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT
      o.id,
      o.name,
      o.slug,
      o.country_code,
      o.created_at,
      p.id   AS plan_id,
      p.name AS plan_name,
      p.amount_xof,
      public.effective_subscription_status(s.status, s.trial_ends_at) AS status,
      s.trial_ends_at,
      (SELECT count(*) FROM public.wedding_events e
        WHERE e.organization_id = o.id) AS events,
      (SELECT count(*) FROM public.organization_memberships m
        WHERE m.organization_id = o.id AND m.status = 'active') AS members,
      (SELECT count(*) FROM public.guests g
         JOIN public.wedding_events e ON e.id = g.event_id
        WHERE e.organization_id = o.id) AS guests,
      (SELECT count(*) FROM public.invitation_quota_ledger l
        WHERE l.organization_id = o.id) AS invitations_sent,
      (SELECT u.email FROM public.organization_memberships m
         JOIN auth.users u ON u.id = m.user_id
        WHERE m.organization_id = o.id AND m.role = 'owner'
        ORDER BY m.created_at LIMIT 1) AS owner_email
    FROM public.organizations o
    LEFT JOIN public.organization_subscriptions s ON s.organization_id = o.id
    LEFT JOIN public.subscription_plans p ON p.id = s.plan_id
    WHERE p_search IS NULL
       OR o.name ILIKE '%' || p_search || '%'
       OR o.slug ILIKE '%' || p_search || '%'
    ORDER BY o.created_at DESC
    LIMIT greatest(coalesce(p_limit, 50), 1)
    OFFSET greatest(coalesce(p_offset, 0), 0)
  ) t;

  RETURN v_rows;
END;
$$;

create or replace function public.admin_list_events(
  p_organization_id uuid default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
DECLARE
  v_rows jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  SELECT coalesce(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.created_at DESC), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT
      e.id,
      e.slug,
      e.title,
      e.bride_name,
      e.groom_name,
      e.created_at,
      o.id   AS organization_id,
      o.name AS organization_name,
      (SELECT count(*) FROM public.guests g WHERE g.event_id = e.id) AS guests,
      (SELECT count(*) FROM public.seating_tables st
        WHERE st.event_id = e.id) AS tables,
      (SELECT count(*) FROM public.invitation_quota_ledger l
        WHERE l.event_id = e.id) AS invitations_sent,
      (SELECT max_invitations FROM public.event_plan_limits(e.id)) AS max_invitations
    FROM public.wedding_events e
    JOIN public.organizations o ON o.id = e.organization_id
    WHERE (p_organization_id IS NULL OR e.organization_id = p_organization_id)
      AND (p_search IS NULL
           OR e.title ILIKE '%' || p_search || '%'
           OR e.slug ILIKE '%' || p_search || '%')
    ORDER BY e.created_at DESC
    LIMIT greatest(coalesce(p_limit, 50), 1)
    OFFSET greatest(coalesce(p_offset, 0), 0)
  ) t;

  RETURN v_rows;
END;
$$;

create or replace function public.admin_list_accounts(
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
DECLARE
  v_rows jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  SELECT coalesce(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.created_at DESC), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT
      u.id,
      u.email,
      u.created_at,
      u.last_sign_in_at,
      exists (
        SELECT 1 FROM public.platform_admins pa WHERE pa.user_id = u.id
      ) AS is_platform_admin,
      coalesce((
        SELECT jsonb_agg(jsonb_build_object(
          'organization_id', o.id,
          'organization_name', o.name,
          'role', m.role,
          'status', m.status
        ) ORDER BY m.created_at)
        FROM public.organization_memberships m
        JOIN public.organizations o ON o.id = m.organization_id
        WHERE m.user_id = u.id
      ), '[]'::jsonb) AS memberships
    FROM auth.users u
    WHERE p_search IS NULL OR u.email ILIKE '%' || p_search || '%'
    ORDER BY u.created_at DESC
    LIMIT greatest(coalesce(p_limit, 50), 1)
    OFFSET greatest(coalesce(p_offset, 0), 0)
  ) t;

  RETURN v_rows;
END;
$$;

create or replace function public.admin_recent_actions(
  p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
DECLARE
  v_rows jsonb;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  SELECT coalesce(jsonb_agg(row_to_json(t)::jsonb ORDER BY t.created_at DESC), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT a.id, a.action, a.target_type, a.target_id, a.details,
           a.created_at, u.email AS actor_email
    FROM public.platform_admin_audit a
    LEFT JOIN auth.users u ON u.id = a.actor_id
    ORDER BY a.created_at DESC
    LIMIT greatest(coalesce(p_limit, 50), 1)
  ) t;

  RETURN v_rows;
END;
$$;

-- ---------------------------------------------------------------------------
-- Console : gestes d'exploitation, tous journalisés.
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_organization_plan(
  p_organization_id uuid,
  p_plan_id text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_previous text;
  v_plan     public.subscription_plans;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  IF coalesce(btrim(p_reason), '') = '' THEN
    RAISE EXCEPTION 'ADMIN_REASON_REQUIRED: Indiquez le motif du changement.';
  END IF;

  SELECT * INTO v_plan FROM public.subscription_plans WHERE id = p_plan_id;
  IF v_plan.id IS NULL THEN
    RAISE EXCEPTION 'ADMIN_PLAN_UNKNOWN: Forfait % introuvable.', p_plan_id;
  END IF;

  SELECT plan_id INTO v_previous
  FROM public.organization_subscriptions
  WHERE organization_id = p_organization_id;

  IF v_previous IS NULL THEN
    RAISE EXCEPTION 'ADMIN_TARGET_UNKNOWN: Cette organisation n''a pas d''abonnement.';
  END IF;

  UPDATE public.organization_subscriptions
  SET plan_id = p_plan_id,
      status = 'active',
      current_period_start = timezone('utc', now()),
      current_period_end = CASE
        WHEN v_plan.billing_interval = 'month'
          THEN timezone('utc', now()) + interval '1 month'
        WHEN v_plan.billing_interval = 'year'
          THEN timezone('utc', now()) + interval '1 year'
        ELSE NULL
      END,
      trial_ends_at = NULL
  WHERE organization_id = p_organization_id;

  PERFORM public.log_platform_admin_action(
    'set_plan', 'organization', p_organization_id,
    jsonb_build_object('from', v_previous, 'to', p_plan_id, 'reason', p_reason)
  );

  RETURN jsonb_build_object('plan_id', p_plan_id, 'previous_plan_id', v_previous);
END;
$$;

create or replace function public.admin_set_organization_status(
  p_organization_id uuid,
  p_status public.subscription_status,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_previous public.subscription_status;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  IF coalesce(btrim(p_reason), '') = '' THEN
    RAISE EXCEPTION 'ADMIN_REASON_REQUIRED: Indiquez le motif du changement.';
  END IF;

  SELECT status INTO v_previous
  FROM public.organization_subscriptions
  WHERE organization_id = p_organization_id;

  IF v_previous IS NULL THEN
    RAISE EXCEPTION 'ADMIN_TARGET_UNKNOWN: Cette organisation n''a pas d''abonnement.';
  END IF;

  UPDATE public.organization_subscriptions
  SET status = p_status,
      trial_ends_at = CASE WHEN p_status = 'trialing' THEN trial_ends_at END
  WHERE organization_id = p_organization_id;

  PERFORM public.log_platform_admin_action(
    'set_status', 'organization', p_organization_id,
    jsonb_build_object('from', v_previous, 'to', p_status, 'reason', p_reason)
  );

  RETURN jsonb_build_object('status', p_status, 'previous_status', v_previous);
END;
$$;

create or replace function public.admin_grant_invitations(
  p_event_id uuid,
  p_extra integer,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_limits record;
BEGIN
  IF NOT public.is_platform_admin() THEN
    RAISE EXCEPTION 'ADMIN_FORBIDDEN: Accès réservé à l''exploitant.';
  END IF;

  IF coalesce(btrim(p_reason), '') = '' THEN
    RAISE EXCEPTION 'ADMIN_REASON_REQUIRED: Indiquez le motif du geste.';
  END IF;

  IF coalesce(p_extra, 0) <= 0 THEN
    RAISE EXCEPTION 'ADMIN_INVALID_AMOUNT: Le crédit doit être positif.';
  END IF;

  INSERT INTO public.invitation_quota_grants (
    event_id, extra_invitations, reason, granted_by
  ) VALUES (p_event_id, p_extra, btrim(p_reason), auth.uid());

  SELECT * INTO v_limits FROM public.event_plan_limits(p_event_id);

  PERFORM public.log_platform_admin_action(
    'grant_invitations', 'event', p_event_id,
    jsonb_build_object('extra', p_extra, 'reason', p_reason)
  );

  RETURN jsonb_build_object(
    'event_id', p_event_id,
    'max_invitations', coalesce(v_limits.max_invitations, -1)
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Droits : seul un utilisateur connecté peut appeler ; la fonction vérifie
-- ensuite elle-même qu'il exploite bien la plateforme.
-- ---------------------------------------------------------------------------
do $$
declare
  v_signature text;
begin
  foreach v_signature in array array[
    'public.admin_list_organizations(text, integer, integer)',
    'public.admin_list_events(uuid, text, integer, integer)',
    'public.admin_list_accounts(text, integer, integer)',
    'public.admin_recent_actions(integer)',
    'public.admin_set_organization_plan(uuid, text, text)',
    'public.admin_set_organization_status(uuid, public.subscription_status, text)',
    'public.admin_grant_invitations(uuid, integer, text)'
  ] loop
    execute format('revoke all on function %s from public, anon', v_signature);
    execute format('grant execute on function %s to authenticated', v_signature);
  end loop;
end;
$$;

-- Nommer le premier exploitant se fait hors application, par exemple :
--   insert into public.platform_admins (user_id, note)
--   select id, 'Fondateur' from auth.users where email = 'vous@exemple.ci'
--   on conflict (user_id) do nothing;
