-- Le forfait gratuit promet un filigrane sur les cartes ; encore faut-il que
-- le portail invité — consulté sans compte, donc en `anon` — puisse savoir
-- s'il doit l'afficher. Les tables d'abonnement restent fermées : seule cette
-- fonction, limitée au strict booléen, traverse la frontière.
create or replace function public.guest_portal_branding(p_guest_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  -- Sans abonnement rattaché (données de démo, mariage créé en SQL) on ne
  -- marque rien, comme les déclencheurs de quota n'y imposent rien.
  select jsonb_build_object(
    'watermark',
    coalesce((p.features ->> 'watermark')::boolean, false),
    'plan_name',
    p.name
  )
  from public.guests g
  join public.wedding_events e on e.id = g.event_id
  left join public.organization_subscriptions s
    on s.organization_id = e.organization_id
  left join public.subscription_plans p on p.id = s.plan_id
  where g.id = p_guest_id;
$$;

comment on function public.guest_portal_branding(uuid) is
  'Indique au portail invité si la carte doit porter le filigrane du forfait gratuit.';

revoke all on function public.guest_portal_branding(uuid) from public;
grant execute on function public.guest_portal_branding(uuid) to anon, authenticated;
