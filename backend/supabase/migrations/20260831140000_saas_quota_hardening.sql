-- Durcissement des quotas.
--
-- Le décompte des envois s'appuyait sur `invitation_deliveries`, une table
-- que l'organisateur peut vider : la politique lui accordait `ALL`, et la
-- suppression d'une invitation (désassignation d'une place, suppression de
-- l'invité) effaçait ses envois en cascade. Trente envois consommés se
-- remettaient donc à zéro en quelques gestes ordinaires.
--
-- On sépare désormais deux choses qui étaient confondues :
--   * `invitation_deliveries` — l'historique, que l'organisateur gère ;
--   * `invitation_quota_ledger` — la consommation, qui ne redescend pas.
--
-- Un envoi consommé l'est définitivement, comme un timbre collé.

create table if not exists public.invitation_quota_ledger (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null
    references public.organizations (id) on delete cascade,
  event_id uuid not null
    references public.wedding_events (id) on delete cascade,
  -- Volontairement sans clé étrangère vers `invitations` : l'invitation peut
  -- disparaître, l'envoi déjà parti chez l'invité, lui, a bien eu lieu.
  invitation_id uuid not null,
  first_sent_at timestamptz not null default timezone('utc', now()),
  unique (event_id, invitation_id)
);

comment on table public.invitation_quota_ledger is
  'Consommation d''envois, insensible aux suppressions. Une ligne par invitation réellement envoyée.';

create index if not exists idx_invitation_quota_ledger_event
  on public.invitation_quota_ledger (event_id);

alter table public.invitation_quota_ledger enable row level security;

-- Lecture seule pour les organisateurs : le registre se remplit par le
-- déclencheur de quota, jamais par le client.
drop policy if exists invitation_quota_ledger_member_select
  on public.invitation_quota_ledger;
create policy invitation_quota_ledger_member_select
  on public.invitation_quota_ledger
  for select
  to authenticated
  using (public.is_event_member(event_id));

revoke insert, update, delete on public.invitation_quota_ledger
  from anon, authenticated;

-- Reprise de l'historique existant : ce qui a déjà été envoyé reste consommé.
insert into public.invitation_quota_ledger (
  organization_id, event_id, invitation_id, first_sent_at
)
select
  e.organization_id,
  d.event_id,
  d.invitation_id,
  min(d.sent_at)
from public.invitation_deliveries d
join public.wedding_events e on e.id = d.event_id
where d.status in ('sent', 'delivered', 'opened')
group by e.organization_id, d.event_id, d.invitation_id
on conflict (event_id, invitation_id) do nothing;

-- ---------------------------------------------------------------------------
-- Le décompte lit et alimente le registre.
-- ---------------------------------------------------------------------------
create or replace function public.enforce_invitation_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_limits record;
  v_used   integer;
  v_org    uuid;
  v_known  boolean;
BEGIN
  IF NEW.status NOT IN ('sent', 'delivered', 'opened') THEN
    RETURN NEW;
  END IF;

  SELECT * INTO v_limits FROM public.event_plan_limits(NEW.event_id);
  IF v_limits.plan_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF v_limits.status IN ('past_due', 'canceled', 'suspended') THEN
    RAISE EXCEPTION
      'QUOTA_SUBSCRIPTION: Le forfait % n''est plus actif. Réactivez-le pour envoyer vos invitations.',
      v_limits.plan_name;
  END IF;

  -- Une relance ne consomme rien : l'invitation est déjà au registre.
  SELECT EXISTS (
    SELECT 1 FROM public.invitation_quota_ledger l
    WHERE l.event_id = NEW.event_id
      AND l.invitation_id = NEW.invitation_id
  ) INTO v_known;
  IF v_known THEN
    RETURN NEW;
  END IF;

  IF v_limits.max_invitations <> -1 THEN
    SELECT count(*) INTO v_used
    FROM public.invitation_quota_ledger l
    WHERE l.event_id = NEW.event_id;

    IF v_used >= v_limits.max_invitations THEN
      RAISE EXCEPTION
        'QUOTA_INVITATIONS: Les % invitations du forfait % sont envoyées. Choisissez un pack pour continuer.',
        v_limits.max_invitations, v_limits.plan_name;
    END IF;
  END IF;

  SELECT organization_id INTO v_org
  FROM public.wedding_events WHERE id = NEW.event_id;

  INSERT INTO public.invitation_quota_ledger (
    organization_id, event_id, invitation_id
  ) VALUES (v_org, NEW.event_id, NEW.invitation_id)
  ON CONFLICT (event_id, invitation_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Le bandeau doit lire le compteur qui refuse, sinon il annonce des envois
-- restants que la base n'accordera pas.
create or replace function public.get_subscription_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
DECLARE
  v_organization_id uuid := public.current_organization_id();
  v_event_id        uuid := public.current_event_id();
  v_subscription    public.organization_subscriptions;
  v_plan            public.subscription_plans;
  v_guests          integer := 0;
  v_invitations     integer := 0;
  v_events          integer := 0;
BEGIN
  IF v_organization_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_subscription
  FROM public.organization_subscriptions
  WHERE organization_id = v_organization_id;

  IF v_subscription.id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans WHERE id = v_subscription.plan_id;

  SELECT count(*) INTO v_events
  FROM public.wedding_events WHERE organization_id = v_organization_id;

  IF v_event_id IS NOT NULL THEN
    SELECT count(*) INTO v_guests
    FROM public.guests WHERE event_id = v_event_id;

    -- Consommation réelle : le registre, et non l'historique effaçable.
    SELECT count(*) INTO v_invitations
    FROM public.invitation_quota_ledger WHERE event_id = v_event_id;
  END IF;

  RETURN jsonb_build_object(
    'status', public.effective_subscription_status(
      v_subscription.status, v_subscription.trial_ends_at),
    'trial_ends_at', v_subscription.trial_ends_at,
    'current_period_end', v_subscription.current_period_end,
    'plan', to_jsonb(v_plan),
    'usage', jsonb_build_object(
      'events', v_events,
      'guests', v_guests,
      'invitations_sent', v_invitations
    )
  );
END;
$$;

-- La RPC renvoie le compteur qui fait foi, pour que l'app affiche le même
-- reste que celui appliqué au prochain envoi.
create or replace function public.record_invitation_delivery(
  p_invitation_id uuid,
  p_channel public.delivery_channel default 'whatsapp',
  p_destination text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_invitation public.invitations;
  v_delivery   public.invitation_deliveries;
  v_limits     record;
  v_used       integer;
BEGIN
  SELECT * INTO v_invitation
  FROM public.invitations WHERE id = p_invitation_id;

  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invitation introuvable.';
  END IF;

  IF NOT public.can_manage_event(v_invitation.event_id) THEN
    RAISE EXCEPTION 'Vous ne gérez pas ce mariage.';
  END IF;

  INSERT INTO public.invitation_deliveries (
    event_id, invitation_id, channel, status,
    destination, sent_at, created_by
  ) VALUES (
    v_invitation.event_id, p_invitation_id, p_channel, 'sent',
    p_destination, timezone('utc', now()), auth.uid()
  ) RETURNING * INTO v_delivery;

  SELECT * INTO v_limits
  FROM public.event_plan_limits(v_invitation.event_id);

  SELECT count(*) INTO v_used
  FROM public.invitation_quota_ledger
  WHERE event_id = v_invitation.event_id;

  RETURN jsonb_build_object(
    'delivery_id', v_delivery.id,
    'invitations_sent', v_used,
    'max_invitations', coalesce(v_limits.max_invitations, -1)
  );
END;
$$;

revoke all on function public.record_invitation_delivery(
  uuid, public.delivery_channel, text) from public, anon;
grant execute on function public.record_invitation_delivery(
  uuid, public.delivery_channel, text) to authenticated;

-- ---------------------------------------------------------------------------
-- L'organisateur gère son historique, mais ne réécrit pas sa consommation.
-- ---------------------------------------------------------------------------
drop policy if exists invitation_deliveries_manager_all
  on public.invitation_deliveries;
drop policy if exists invitation_deliveries_manager_insert
  on public.invitation_deliveries;

create policy invitation_deliveries_manager_insert
  on public.invitation_deliveries
  for insert
  to authenticated
  with check (public.can_manage_event(event_id));

-- Ni UPDATE ni DELETE : le statut d'un envoi n'appartient plus au client.
-- Le support passe par `service_role`, qui n'est pas soumis à RLS.

-- ---------------------------------------------------------------------------
-- Le quota d'invités doit aussi tenir au déplacement, pas seulement à l'ajout.
-- ---------------------------------------------------------------------------
drop trigger if exists trg_guests_quota on public.guests;
create trigger trg_guests_quota
  before insert or update of event_id on public.guests
  for each row execute function public.enforce_guest_quota();

-- ---------------------------------------------------------------------------
-- Plus aucune organisation sans forfait : sans abonnement rattaché, aucun
-- déclencheur ne s'appliquait. Le parcours d'inscription en crée déjà un ;
-- ce filet couvre les organisations créées autrement.
-- ---------------------------------------------------------------------------
create or replace function public.attach_default_subscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
DECLARE
  v_plan record;
BEGIN
  SELECT * INTO v_plan FROM public.default_signup_plan();
  IF v_plan.id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.organization_subscriptions (
    organization_id, plan_id, status
  ) VALUES (NEW.id, v_plan.id, 'active')
  ON CONFLICT (organization_id) DO NOTHING;

  RETURN NEW;
END;
$$;

drop trigger if exists trg_organizations_default_subscription
  on public.organizations;
create trigger trg_organizations_default_subscription
  after insert on public.organizations
  for each row execute function public.attach_default_subscription();

-- Rattrapage des organisations existantes restées sans forfait.
insert into public.organization_subscriptions (organization_id, plan_id, status)
select o.id, (select id from public.default_signup_plan()), 'active'
from public.organizations o
where not exists (
  select 1 from public.organization_subscriptions s
  where s.organization_id = o.id
)
on conflict (organization_id) do nothing;

-- ---------------------------------------------------------------------------
-- Expiration des essais professionnels : planifiée si pg_cron est présent,
-- sinon `effective_subscription_status()` requalifie déjà à la lecture.
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule('expire-stale-subscriptions')
    where exists (
      select 1 from cron.job where jobname = 'expire-stale-subscriptions'
    );
    perform cron.schedule(
      'expire-stale-subscriptions',
      '17 3 * * *',
      $cron$select public.expire_stale_subscriptions();$cron$
    );
  end if;
end;
$$;
