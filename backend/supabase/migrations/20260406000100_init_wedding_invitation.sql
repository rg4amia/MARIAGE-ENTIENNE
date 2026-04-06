create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'invitation_status') then
    create type public.invitation_status as enum (
      'draft',
      'pending_media',
      'media_uploaded',
      'card_unlocked'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'guest_media_type') then
    create type public.guest_media_type as enum ('audio', 'video');
  end if;
end $$;

create table if not exists public.wedding_events (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  bride_name text not null,
  groom_name text not null,
  location text,
  event_date timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  role public.app_role not null default 'admin',
  full_name text not null,
  phone text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.guests (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  full_name text not null,
  phone text,
  email text,
  qr_token text not null unique default encode(gen_random_bytes(16), 'hex'),
  status public.invitation_status not null default 'draft',
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.seating_tables (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  label text not null,
  capacity integer not null check (capacity > 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (event_id, label)
);

create table if not exists public.chairs (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  table_id uuid not null references public.seating_tables(id) on delete cascade,
  chair_number integer not null check (chair_number > 0),
  guest_id uuid unique references public.guests(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (table_id, chair_number)
);

create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  guest_id uuid not null unique references public.guests(id) on delete cascade,
  table_id uuid not null references public.seating_tables(id) on delete cascade,
  chair_id uuid not null references public.chairs(id) on delete cascade,
  invitation_code text not null unique,
  web_url text not null,
  deep_link text not null,
  qr_payload text not null,
  png_storage_path text,
  pdf_storage_path text,
  is_unlocked boolean not null default false,
  unlocked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.guest_media_submissions (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.wedding_events(id) on delete cascade,
  guest_id uuid not null references public.guests(id) on delete cascade,
  invitation_id uuid not null references public.invitations(id) on delete cascade,
  media_type public.guest_media_type not null,
  storage_path text not null,
  mime_type text,
  file_size_bytes bigint,
  client_duration_seconds numeric(8,2) not null,
  server_duration_seconds numeric(8,2),
  client_validated boolean not null default false,
  server_validated boolean not null default false,
  validation_notes text,
  submitted_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_wedding_events_updated_at on public.wedding_events;
create trigger trg_wedding_events_updated_at
before update on public.wedding_events
for each row execute function public.handle_updated_at();

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

drop trigger if exists trg_guests_updated_at on public.guests;
create trigger trg_guests_updated_at
before update on public.guests
for each row execute function public.handle_updated_at();

drop trigger if exists trg_tables_updated_at on public.seating_tables;
create trigger trg_tables_updated_at
before update on public.seating_tables
for each row execute function public.handle_updated_at();

drop trigger if exists trg_chairs_updated_at on public.chairs;
create trigger trg_chairs_updated_at
before update on public.chairs
for each row execute function public.handle_updated_at();

drop trigger if exists trg_invitations_updated_at on public.invitations;
create trigger trg_invitations_updated_at
before update on public.invitations
for each row execute function public.handle_updated_at();

create or replace function public.current_event_id()
returns uuid
language sql
stable
as $$
  select event_id
  from public.profiles
  where id = auth.uid()
  limit 1
$$;

create or replace function public.assign_guest_to_chair(
  p_guest_id uuid,
  p_chair_id uuid,
  p_public_base_url text default 'https://mariage-entienne.app',
  p_deep_link_base text default 'mariageentienne://guest'
)
returns public.invitations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guest public.guests;
  v_chair public.chairs;
  v_table public.seating_tables;
  v_token text;
  v_invitation public.invitations;
begin
  select * into v_guest
  from public.guests
  where id = p_guest_id;

  if v_guest.id is null then
    raise exception 'Guest not found';
  end if;

  select * into v_chair
  from public.chairs
  where id = p_chair_id;

  if v_chair.id is null then
    raise exception 'Chair not found';
  end if;

  if v_chair.guest_id is not null and v_chair.guest_id <> p_guest_id then
    raise exception 'Chair already assigned';
  end if;

  update public.chairs
  set guest_id = null
  where guest_id = p_guest_id;

  update public.chairs
  set guest_id = p_guest_id
  where id = p_chair_id;

  select * into v_table
  from public.seating_tables
  where id = v_chair.table_id;

  v_token := coalesce(
    (select qr_token from public.guests where id = p_guest_id),
    encode(gen_random_bytes(16), 'hex')
  );

  update public.guests
  set qr_token = v_token,
      status = 'pending_media'
  where id = p_guest_id;

  insert into public.invitations (
    event_id,
    guest_id,
    table_id,
    chair_id,
    invitation_code,
    web_url,
    deep_link,
    qr_payload
  )
  values (
    v_guest.event_id,
    p_guest_id,
    v_table.id,
    p_chair_id,
    upper(left(v_token, 8)),
    p_public_base_url || '/guest/' || v_token,
    p_deep_link_base || '/' || v_token,
    p_public_base_url || '/guest/' || v_token
  )
  on conflict (guest_id) do update set
    table_id = excluded.table_id,
    chair_id = excluded.chair_id,
    invitation_code = excluded.invitation_code,
    web_url = excluded.web_url,
    deep_link = excluded.deep_link,
    qr_payload = excluded.qr_payload,
    updated_at = timezone('utc', now())
  returning * into v_invitation;

  return v_invitation;
end;
$$;

create or replace function public.validate_media_submission(
  p_submission_id uuid,
  p_server_duration_seconds numeric default null,
  p_notes text default null
)
returns table (
  is_valid boolean,
  invitation_unlocked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_submission public.guest_media_submissions;
  v_client_valid boolean;
  v_server_valid boolean;
begin
  update public.guest_media_submissions
  set server_duration_seconds = coalesce(
        p_server_duration_seconds,
        server_duration_seconds,
        client_duration_seconds
      ),
      validation_notes = coalesce(p_notes, validation_notes)
  where id = p_submission_id;

  select * into v_submission
  from public.guest_media_submissions
  where id = p_submission_id;

  if v_submission.id is null then
    raise exception 'Submission not found';
  end if;

  v_client_valid := v_submission.client_duration_seconds >= 30;
  v_server_valid := coalesce(v_submission.server_duration_seconds, 0) >= 30;

  update public.guest_media_submissions
  set client_validated = v_client_valid,
      server_validated = v_server_valid
  where id = p_submission_id;

  if v_client_valid and v_server_valid then
    update public.invitations
    set is_unlocked = true,
        unlocked_at = timezone('utc', now())
    where id = v_submission.invitation_id;

    update public.guests
    set status = 'card_unlocked'
    where id = v_submission.guest_id;

    return query select true, true;
  end if;

  update public.guests
  set status = 'media_uploaded'
  where id = v_submission.guest_id;

  return query select false, false;
end;
$$;

create or replace function public.get_invitation_by_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'id', i.id,
    'guest_id', g.id,
    'guest_name', g.full_name,
    'table_id', t.id,
    'table_label', t.label,
    'chair_id', c.id,
    'chair_number', c.chair_number,
    'token', g.qr_token,
    'invitation_code', i.invitation_code,
    'web_url', i.web_url,
    'deep_link', i.deep_link,
    'is_unlocked', i.is_unlocked,
    'png_storage_path', i.png_storage_path,
    'pdf_storage_path', i.pdf_storage_path,
    'event', jsonb_build_object(
      'id', e.id,
      'title', e.title,
      'bride_name', e.bride_name,
      'groom_name', e.groom_name,
      'location', coalesce(e.location, ''),
      'event_date_label', coalesce(to_char(e.event_date, 'DD Mon YYYY'), '')
    ),
    'media_submissions', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'id', gm.id,
            'invitation_id', gm.invitation_id,
            'guest_id', gm.guest_id,
            'media_type', gm.media_type,
            'storage_path', gm.storage_path,
            'client_duration_seconds', gm.client_duration_seconds,
            'server_duration_seconds', gm.server_duration_seconds,
            'client_validated', gm.client_validated,
            'server_validated', gm.server_validated,
            'submitted_at', gm.submitted_at
          )
          order by gm.submitted_at asc
        )
        from public.guest_media_submissions gm
        where gm.invitation_id = i.id
      ),
      '[]'::jsonb
    )
  )
  into v_result
  from public.guests g
  join public.invitations i on i.guest_id = g.id
  join public.seating_tables t on t.id = i.table_id
  join public.chairs c on c.id = i.chair_id
  join public.wedding_events e on e.id = i.event_id
  where g.qr_token = p_token;

  return v_result;
end;
$$;

create or replace function public.submit_guest_media_by_token(
  p_token text,
  p_media_type public.guest_media_type,
  p_storage_path text,
  p_client_duration_seconds numeric,
  p_server_duration_seconds numeric default null,
  p_mime_type text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_guest public.guests;
  v_invitation public.invitations;
  v_submission_id uuid;
begin
  select * into v_guest
  from public.guests
  where qr_token = p_token;

  if v_guest.id is null then
    raise exception 'Invitation token not found';
  end if;

  select * into v_invitation
  from public.invitations
  where guest_id = v_guest.id;

  if v_invitation.id is null then
    raise exception 'Invitation not found';
  end if;

  insert into public.guest_media_submissions (
    event_id,
    guest_id,
    invitation_id,
    media_type,
    storage_path,
    mime_type,
    client_duration_seconds,
    server_duration_seconds,
    client_validated,
    server_validated
  )
  values (
    v_guest.event_id,
    v_guest.id,
    v_invitation.id,
    p_media_type,
    p_storage_path,
    p_mime_type,
    p_client_duration_seconds,
    coalesce(p_server_duration_seconds, p_client_duration_seconds),
    p_client_duration_seconds >= 30,
    coalesce(p_server_duration_seconds, p_client_duration_seconds) >= 30
  )
  returning id into v_submission_id;

  perform public.validate_media_submission(
    v_submission_id,
    coalesce(p_server_duration_seconds, p_client_duration_seconds),
    'Validation executee via RPC publique par token.'
  );

  return public.get_invitation_by_token(p_token);
end;
$$;

alter table public.wedding_events enable row level security;
alter table public.profiles enable row level security;
alter table public.guests enable row level security;
alter table public.seating_tables enable row level security;
alter table public.chairs enable row level security;
alter table public.invitations enable row level security;
alter table public.guest_media_submissions enable row level security;

create policy "admins_select_event"
on public.wedding_events
for select
to authenticated
using (id = public.current_event_id());

create policy "admins_manage_profiles"
on public.profiles
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

create policy "admins_manage_guests"
on public.guests
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

create policy "admins_manage_tables"
on public.seating_tables
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

create policy "admins_manage_chairs"
on public.chairs
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

create policy "admins_manage_invitations"
on public.invitations
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

create policy "admins_manage_media"
on public.guest_media_submissions
for all
to authenticated
using (event_id = public.current_event_id())
with check (event_id = public.current_event_id());

insert into storage.buckets (id, name, public)
values
  ('guest-media', 'guest-media', false),
  ('invitation-cards-png', 'invitation-cards-png', false),
  ('invitation-cards-pdf', 'invitation-cards-pdf', false)
on conflict (id) do nothing;

create policy "admins_access_guest_media_bucket"
on storage.objects
for all
to authenticated
using (bucket_id = 'guest-media')
with check (bucket_id = 'guest-media');

create policy "admins_access_png_bucket"
on storage.objects
for all
to authenticated
using (bucket_id = 'invitation-cards-png')
with check (bucket_id = 'invitation-cards-png');

create policy "admins_access_pdf_bucket"
on storage.objects
for all
to authenticated
using (bucket_id = 'invitation-cards-pdf')
with check (bucket_id = 'invitation-cards-pdf');

grant execute on function public.get_invitation_by_token(text) to anon, authenticated;
grant execute on function public.submit_guest_media_by_token(
  text,
  public.guest_media_type,
  text,
  numeric,
  numeric,
  text
) to anon, authenticated;
