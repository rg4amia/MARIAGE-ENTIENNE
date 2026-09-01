-- Expose les lieux du mariage (mairie, église, réception...) au portail
-- invité public, sur le même modèle que guest_portal_branding : scoping par
-- guest_id déjà vérifié côté client, aucun accès direct anon à event_venues.

create or replace function public.guest_portal_venues(p_guest_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', v.id,
      'event_id', v.event_id,
      'venue_type', v.venue_type,
      'name', v.name,
      'address_line', v.address_line,
      'city', v.city,
      'latitude', v.latitude,
      'longitude', v.longitude,
      'maps_url', v.maps_url,
      'starts_at', v.starts_at,
      'instructions', v.instructions,
      'sort_order', v.sort_order
    ) order by v.sort_order, v.name
  ), '[]'::jsonb)
  from public.guests g
  join public.event_venues v on v.event_id = g.event_id
  where g.id = p_guest_id;
$$;

comment on function public.guest_portal_venues(uuid) is
  'Liste les lieux du mariage (avec itinéraire) pour le portail invité, scopée au mariage de ce guest.';

revoke all on function public.guest_portal_venues(uuid) from public;
grant execute on function public.guest_portal_venues(uuid) to anon, authenticated;
