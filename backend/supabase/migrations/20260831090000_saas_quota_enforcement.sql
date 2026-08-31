-- ============================================================
-- Application réelle des quotas de forfait
--
-- Jusqu'ici les limites n'étaient que déclaratives : l'application
-- affichait un forfait que rien n'imposait. Cette migration place la
-- contrainte au seul endroit qu'aucun client ne peut contourner — la
-- base — et fournit le chaînon manquant : l'enregistrement d'un envoi
-- d'invitation, sans lequel le quota resterait éternellement à zéro.
--
-- Principe : en l'absence d'abonnement rattaché (données de démo,
-- scripts d'administration, migrations), on n'impose rien. Un quota
-- introuvable ne doit jamais bloquer une écriture légitime.
-- ============================================================

-- ============================================================
-- 1. FORFAIT EFFECTIF D'UN ÉVÉNEMENT
-- ============================================================

-- Statut réel de l'abonnement, essai périmé compris.
CREATE OR REPLACE FUNCTION public.effective_subscription_status(
  p_status public.subscription_status,
  p_trial_ends_at timestamptz
)
RETURNS public.subscription_status
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_status = 'trialing'
     AND p_trial_ends_at IS NOT NULL
     AND p_trial_ends_at < timezone('utc', now())
    THEN 'past_due'::public.subscription_status
    ELSE p_status
  END;
$$;

-- Forfait et statut applicables à un événement, indépendamment de
-- l'utilisateur courant : les déclencheurs s'exécutent aussi depuis des
-- fonctions SECURITY DEFINER où `auth.uid()` n'est pas parlant.
CREATE OR REPLACE FUNCTION public.event_plan_limits(p_event_id uuid)
RETURNS TABLE (
  plan_id text,
  plan_name text,
  max_guests_per_event integer,
  max_invitations integer,
  collaborators integer,
  status public.subscription_status
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.name,
    p.max_guests_per_event,
    p.max_invitations,
    coalesce((p.features ->> 'collaborators')::integer, -1),
    public.effective_subscription_status(s.status, s.trial_ends_at)
  FROM public.wedding_events e
  JOIN public.organization_subscriptions s
    ON s.organization_id = e.organization_id
  JOIN public.subscription_plans p ON p.id = s.plan_id
  WHERE e.id = p_event_id;
$$;

-- ============================================================
-- 2. QUOTA D'INVITÉS
-- ============================================================

CREATE OR REPLACE FUNCTION public.enforce_guest_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limits record;
  v_count  integer;
BEGIN
  SELECT * INTO v_limits FROM public.event_plan_limits(NEW.event_id);

  IF v_limits.plan_id IS NULL
     OR v_limits.max_guests_per_event = -1 THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.guests
  WHERE event_id = NEW.event_id;

  IF v_count >= v_limits.max_guests_per_event THEN
    RAISE EXCEPTION
      'QUOTA_GUESTS: Le forfait % est limité à % invités. Choisissez un pack supérieur pour en ajouter davantage.',
      v_limits.plan_name, v_limits.max_guests_per_event;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guests_quota ON public.guests;
CREATE TRIGGER trg_guests_quota
  BEFORE INSERT ON public.guests
  FOR EACH ROW EXECUTE FUNCTION public.enforce_guest_quota();

-- ============================================================
-- 3. QUOTA D'INVITATIONS ENVOYÉES
--
-- Le quota porte sur les invitations distinctes réellement parties :
-- renvoyer la même invitation à un invité qui l'a perdue ne doit pas
-- coûter une unité de plus.
-- ============================================================

CREATE OR REPLACE FUNCTION public.enforce_invitation_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limits  record;
  v_used    integer;
  v_resend  boolean;
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

  IF v_limits.max_invitations = -1 THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.invitation_deliveries d
    WHERE d.invitation_id = NEW.invitation_id
      AND d.status IN ('sent', 'delivered', 'opened')
      AND d.id IS DISTINCT FROM NEW.id
  ) INTO v_resend;
  IF v_resend THEN
    RETURN NEW;
  END IF;

  SELECT count(DISTINCT d.invitation_id) INTO v_used
  FROM public.invitation_deliveries d
  WHERE d.event_id = NEW.event_id
    AND d.status IN ('sent', 'delivered', 'opened')
    AND d.id IS DISTINCT FROM NEW.id;

  IF v_used >= v_limits.max_invitations THEN
    RAISE EXCEPTION
      'QUOTA_INVITATIONS: Les % invitations du forfait % sont envoyées. Choisissez un pack pour continuer.',
      v_limits.max_invitations, v_limits.plan_name;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_invitation_deliveries_quota
  ON public.invitation_deliveries;
CREATE TRIGGER trg_invitation_deliveries_quota
  BEFORE INSERT OR UPDATE OF status ON public.invitation_deliveries
  FOR EACH ROW EXECUTE FUNCTION public.enforce_invitation_quota();

-- ============================================================
-- 4. QUOTA DE COLLABORATEURS
-- ============================================================

CREATE OR REPLACE FUNCTION public.enforce_collaborator_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_max   integer;
  v_name  text;
  v_count integer;
BEGIN
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  SELECT coalesce((p.features ->> 'collaborators')::integer, -1), p.name
  INTO v_max, v_name
  FROM public.organization_subscriptions s
  JOIN public.subscription_plans p ON p.id = s.plan_id
  WHERE s.organization_id = NEW.organization_id;

  IF v_max IS NULL OR v_max = -1 THEN
    RETURN NEW;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.organization_memberships
  WHERE organization_id = NEW.organization_id
    AND status = 'active'
    AND user_id IS DISTINCT FROM NEW.user_id;

  IF v_count >= v_max THEN
    RAISE EXCEPTION
      'QUOTA_COLLABORATORS: Le forfait % autorise % personne(s) sur l''espace.',
      v_name, v_max;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_memberships_quota
  ON public.organization_memberships;
CREATE TRIGGER trg_memberships_quota
  BEFORE INSERT OR UPDATE OF status ON public.organization_memberships
  FOR EACH ROW EXECUTE FUNCTION public.enforce_collaborator_quota();

-- ============================================================
-- 5. ENREGISTREMENT D'UN ENVOI
--
-- Chaînon manquant : l'application partageait les invitations sans rien
-- consigner, si bien que la consommation restait nulle et qu'aucun quota
-- ne pouvait s'appliquer.
-- ============================================================

CREATE OR REPLACE FUNCTION public.record_invitation_delivery(
  p_invitation_id uuid,
  p_channel public.delivery_channel DEFAULT 'whatsapp',
  p_destination text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitation public.invitations;
  v_limits     record;
  v_delivery   public.invitation_deliveries;
  v_used       integer;
BEGIN
  SELECT * INTO v_invitation
  FROM public.invitations
  WHERE id = p_invitation_id;

  IF v_invitation.id IS NULL THEN
    RAISE EXCEPTION 'Invitation introuvable';
  END IF;

  IF NOT public.can_manage_event(v_invitation.event_id) THEN
    RAISE EXCEPTION 'Droits insuffisants sur ce mariage';
  END IF;

  -- Le déclencheur de quota s'applique aussi ici : c'est lui qui refuse.
  INSERT INTO public.invitation_deliveries (
    event_id, invitation_id, channel, status,
    destination, sent_at, created_by
  ) VALUES (
    v_invitation.event_id, p_invitation_id, p_channel, 'sent',
    p_destination, timezone('utc', now()), auth.uid()
  ) RETURNING * INTO v_delivery;

  SELECT * INTO v_limits
  FROM public.event_plan_limits(v_invitation.event_id);

  SELECT count(DISTINCT d.invitation_id) INTO v_used
  FROM public.invitation_deliveries d
  WHERE d.event_id = v_invitation.event_id
    AND d.status IN ('sent', 'delivered', 'opened');

  RETURN jsonb_build_object(
    'delivery_id', v_delivery.id,
    'invitations_sent', v_used,
    'max_invitations', coalesce(v_limits.max_invitations, -1)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.record_invitation_delivery(
  uuid, public.delivery_channel, text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.record_invitation_delivery(
  uuid, public.delivery_channel, text) TO authenticated;

-- ============================================================
-- 6. PÉREMPTION DES ESSAIS
--
-- Rien ne faisait expirer un essai. `effective_subscription_status`
-- traite déjà le cas en lecture ; cette fonction matérialise la bascule
-- pour un travail planifié (pg_cron ou appel externe).
-- ============================================================

CREATE OR REPLACE FUNCTION public.expire_stale_subscriptions()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.organization_subscriptions
  SET status = 'past_due'::public.subscription_status,
      updated_at = timezone('utc', now())
  WHERE status = 'trialing'
    AND trial_ends_at IS NOT NULL
    AND trial_ends_at < timezone('utc', now());

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_stale_subscriptions() FROM public, anon, authenticated;

-- ============================================================
-- 7. LE RÉCAPITULATIF REFLÈTE LE STATUT EFFECTIF
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_subscription_overview()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
  FROM public.subscription_plans
  WHERE id = v_subscription.plan_id;

  SELECT count(*) INTO v_events
  FROM public.wedding_events
  WHERE organization_id = v_organization_id
    AND status <> 'archived';

  IF v_event_id IS NOT NULL THEN
    SELECT count(*) INTO v_guests
    FROM public.guests
    WHERE event_id = v_event_id;

    -- Une invitation renvoyée ne consomme pas deux fois le quota.
    SELECT count(DISTINCT invitation_id) INTO v_invitations
    FROM public.invitation_deliveries
    WHERE event_id = v_event_id
      AND status IN ('sent', 'delivered', 'opened');
  END IF;

  RETURN jsonb_build_object(
    'status', public.effective_subscription_status(
      v_subscription.status, v_subscription.trial_ends_at),
    'trial_ends_at', v_subscription.trial_ends_at,
    'current_period_end', v_subscription.current_period_end,
    'plan', jsonb_build_object(
      'id', v_plan.id,
      'name', v_plan.name,
      'description', v_plan.description,
      'amount_xof', v_plan.amount_xof,
      'billing_interval', v_plan.billing_interval,
      'plan_kind', v_plan.plan_kind,
      'max_events', v_plan.max_events,
      'max_guests_per_event', v_plan.max_guests_per_event,
      'max_invitations', v_plan.max_invitations,
      'max_storage_mb', v_plan.max_storage_mb,
      'features', v_plan.features
    ),
    'usage', jsonb_build_object(
      'events', v_events,
      'guests', v_guests,
      'invitations_sent', v_invitations
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_subscription_overview() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_subscription_overview() TO authenticated;
