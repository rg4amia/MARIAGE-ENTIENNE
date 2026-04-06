insert into public.seating_tables (
  id,
  event_id,
  label,
  capacity
)
values
  (
    '00000000-0000-0000-0000-000000000201',
    '00000000-0000-0000-0000-000000000001',
    'Famille',
    6
  ),
  (
    '00000000-0000-0000-0000-000000000202',
    '00000000-0000-0000-0000-000000000001',
    'Amis',
    8
  )
on conflict (id) do nothing;

insert into public.chairs (
  id,
  event_id,
  table_id,
  chair_number,
  guest_id
)
values
  (
    '00000000-0000-0000-0000-000000000301',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    1,
    '00000000-0000-0000-0000-000000000101'
  ),
  (
    '00000000-0000-0000-0000-000000000302',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    2,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000303',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    3,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000304',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    4,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000305',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    5,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000306',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000201',
    6,
    null
  )
on conflict (id) do nothing;

update public.guests
set
  qr_token = 'stephanie-k-001',
  status = 'pending_media'
where id = '00000000-0000-0000-0000-000000000101';

insert into public.invitations (
  id,
  event_id,
  guest_id,
  table_id,
  chair_id,
  invitation_code,
  web_url,
  deep_link,
  qr_payload,
  is_unlocked
)
values (
  '00000000-0000-0000-0000-000000000401',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000101',
  '00000000-0000-0000-0000-000000000201',
  '00000000-0000-0000-0000-000000000301',
  'STEPH001',
  'https://your-web-host/#/guest/stephanie-k-001',
  'mariageentienne://guest/stephanie-k-001',
  'https://your-web-host/#/guest/stephanie-k-001',
  false
)
on conflict (guest_id) do update set
  table_id = excluded.table_id,
  chair_id = excluded.chair_id,
  invitation_code = excluded.invitation_code,
  web_url = excluded.web_url,
  deep_link = excluded.deep_link,
  qr_payload = excluded.qr_payload,
  is_unlocked = excluded.is_unlocked,
  updated_at = timezone('utc', now());
