insert into public.wedding_events (
  id,
  slug,
  title,
  bride_name,
  groom_name,
  location,
  event_date
)
values (
  '00000000-0000-0000-0000-000000000001',
  'mariage-entienne',
  'Mariage Entienne',
  'Aimee',
  'Entienne',
  'Abidjan',
  timezone('utc', now()) + interval '120 days'
)
on conflict (id) do nothing;

insert into public.guests (
  id,
  event_id,
  full_name,
  phone,
  email,
  status
)
values
  (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000001',
    'Stephanie K.',
    '+2250102030405',
    'stephanie@example.com',
    'draft'
  ),
  (
    '00000000-0000-0000-0000-000000000102',
    '00000000-0000-0000-0000-000000000001',
    'Jean M.',
    '+2250504030201',
    'jean@example.com',
    'draft'
  )
on conflict (id) do nothing;
