-- =============================================================================
-- Safai Setu — Supabase setup
-- Run this whole file once in the Supabase SQL Editor (Dashboard → SQL Editor).
-- It is idempotent: re-running it is safe.
--
-- What it does:
--   1. public.profiles  — one row per auth user, role backed by the DB.
--   2. public.complaints — citizen complaints with real latitude/longitude.
--   3. Row Level Security on both tables.
--   4. Storage bucket "complaint-photos" + policies.
--
-- Security model (one auth system, roles from the database):
--   * Citizens sign in with Google. New accounts get role = 'citizen'.
--   * Workers and Heads sign in with email + password; their accounts are
--     created by an administrator in Supabase Authentication, and their role
--     is assigned from this trusted environment (SQL editor / service role),
--     never by the Flutter client.
--   * A Head (role = 'head') can promote an existing account to 'worker'
--     from the Head app (assigns Worker ID + vehicle).
--   * No user can change their OWN role / worker_id / vehicle_number.
--   * A role supplied by the Flutter client is never trusted for privilege.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. PROFILES TABLE
-- -----------------------------------------------------------------------------
create table if not exists public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  full_name        text,
  email            text,
  avatar_url       text,
  role             text not null default 'citizen',
  phone            text,
  worker_id        text,
  vehicle_number   text,
  password_set     boolean not null default false,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

-- Safe additions in case the table already exists from an earlier version.
alter table public.profiles add column if not exists role           text not null default 'citizen';
alter table public.profiles add column if not exists worker_id      text;
alter table public.profiles add column if not exists vehicle_number text;
alter table public.profiles add column if not exists phone          text;
alter table public.profiles add column if not exists avatar_url     text;
alter table public.profiles add column if not exists password_set   boolean not null default false;
alter table public.profiles add column if not exists updated_at     timestamptz not null default now();

-- Restrict role values.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('citizen', 'worker', 'head'));

-- updated_at maintenance.
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------------------------
-- 2. AUTO-CREATE A PROFILE WHEN A NEW AUTH USER SIGNS UP (Google Sign-In)
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url, role)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, ''), '@', 1),
      'User'
    ),
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    ),
    'citizen'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY — PROFILES
-- -----------------------------------------------------------------------------
-- Security-definer helpers avoid RLS recursion when policies query profiles.
create or replace function public.is_head()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'head'
  );
$$;

create or replace function public.is_worker()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'worker'
  );
$$;

create or replace function public.is_citizen()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'citizen'
  );
$$;

-- Helper: returns the Worker ID (e.g. WK-1002) of the currently signed-in
-- user, or NULL. security definer + search_path = public so it reads profiles
-- DIRECTLY, bypassing RLS on profiles entirely. Defined early so policies
-- below can reference it.
create or replace function public.worker_id_of_current_user()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select worker_id from public.profiles where id = auth.uid();
$$;

-- Helper: can the current worker read a given citizen's profile (phone)? True
-- when the citizen has at least one complaint assigned to this worker.
-- security definer + search_path = public so it reads complaints DIRECTLY,
-- bypassing RLS. A plain EXISTS over complaints inside a profiles policy would
-- trigger the complaints policies, which read profiles back — infinite
-- recursion (42P17). The helper breaks that cycle.
create or replace function public.can_worker_see_citizen(v_citizen_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.complaints c
    where c.citizen_id = v_citizen_id
      and c.assigned_to = public.worker_id_of_current_user()
  );
$$;

-- Helper: can the current citizen see a given worker's profile? True when the
-- citizen has a complaint assigned to that worker ID. security definer reads
-- complaints DIRECTLY, bypassing RLS, so it cannot recurse.
create or replace function public.can_citizen_see_worker(v_worker_id text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.complaints c
    where c.citizen_id = auth.uid()
      and c.assigned_to = v_worker_id
  );
$$;

alter table public.profiles enable row level security;

-- Users can read their own profile; heads can read everyone (worker management).
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select
  using (auth.uid() = id or public.is_head());

-- Workers can read the contact details (phone) of citizens whose complaint is
-- assigned to them, so the worker can call the citizen about the work. Uses
-- the security-definer helper so it never re-enters the complaints policies
-- (which would recurse back into profiles — 42P17).
drop policy if exists "profiles_select_worker_assigned" on public.profiles;
create policy "profiles_select_worker_assigned" on public.profiles
  for select
  using (
    public.is_worker()
    and public.can_worker_see_citizen(public.profiles.id)
  );

-- Citizens can read the name/phone of the worker assigned to their own
-- complaint, so they know who is coming and can call them. Uses the
-- security-definer helper to avoid RLS recursion.
drop policy if exists "profiles_select_citizen_worker" on public.profiles;
create policy "profiles_select_citizen_worker" on public.profiles
  for select
  using (
    public.profiles.role = 'worker'
    and public.can_citizen_see_worker(public.profiles.worker_id)
  );

-- Citizen: can read every worker's profile (name + vehicle number) for the
-- city map's "Track Collection Vehicle" page. Kept to workers only.
drop policy if exists "profiles_select_citizen_all_workers" on public.profiles;
create policy "profiles_select_citizen_all_workers" on public.profiles
  for select
  using (public.is_citizen() and public.profiles.role = 'worker');

-- A client can only create its OWN row, and only as a citizen.
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert
  with check (auth.uid() = id and role = 'citizen');

-- Users can update their own harmless fields (name/avatar/phone/email).
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Heads can update any profile (promote/demote workers, assign vehicle, etc.).
drop policy if exists "profiles_update_head" on public.profiles;
create policy "profiles_update_head" on public.profiles
  for update
  using (public.is_head())
  with check (public.is_head());

-- A citizen can never change their own role / worker_id / vehicle_number,
-- even if they find a way to call UPDATE with those columns.
create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() = old.id then
    if new.role is distinct from old.role
       or new.worker_id is distinct from old.worker_id
       or new.vehicle_number is distinct from old.vehicle_number then
      raise exception 'Citizens cannot change their own role, Worker ID, or vehicle number.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_self_role_change on public.profiles;
create trigger prevent_self_role_change
  before update on public.profiles
  for each row execute function public.prevent_self_role_change();

-- No delete policy: profiles are never deleted by the app.

-- -----------------------------------------------------------------------------
-- 4. COMPLAINTS TABLE (with real GPS coordinates)
-- -----------------------------------------------------------------------------
create table if not exists public.complaints (
  id                   uuid primary key default gen_random_uuid(),
  citizen_id           uuid not null references auth.users (id) on delete cascade,
  category             text not null,
  description          text not null default '',
  location_text        text,
  latitude             double precision,
  longitude            double precision,
  photo_url            text,
  status               text not null default 'pending',
  timeline_step        int not null default 0,
  assigned_to          text,
  estimated_resolution text,
  rejection_reason     text,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Safe additions for tables created by an earlier version of the app.
alter table public.complaints add column if not exists latitude             double precision;
alter table public.complaints add column if not exists longitude            double precision;
alter table public.complaints add column if not exists photo_url            text;
alter table public.complaints add column if not exists location_text        text;
alter table public.complaints add column if not exists status               text not null default 'pending';
alter table public.complaints add column if not exists timeline_step        int not null default 0;
alter table public.complaints add column if not exists assigned_to          text;
alter table public.complaints add column if not exists estimated_resolution text;
alter table public.complaints add column if not exists rejection_reason     text;
alter table public.complaints add column if not exists updated_at           timestamptz not null default now();

alter table public.complaints drop constraint if exists complaints_status_check;
alter table public.complaints add constraint complaints_status_check
  check (status in ('pending', 'assigned', 'in_progress', 'resolved', 'rejected'));

drop trigger if exists set_complaints_updated_at on public.complaints;
create trigger set_complaints_updated_at
  before update on public.complaints
  for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------------------------
-- 4b. COMPLAINT NUMBERS — short, human-readable IDs shown to users
-- -----------------------------------------------------------------------------
-- The `id` column stays a UUID (used internally for routing, tasks and
-- notifications). `complaint_number` is the ID users actually see, e.g.
-- SS-260815-001 (SS = Safai Setu, YYMMDD = report date, NNN = per-day
-- counter). New complaints get a number automatically; existing rows are
-- backfilled below (idempotent — safe to re-run).
-- =============================================================================

alter table public.complaints add column if not exists complaint_number text;

-- Backfill every existing complaint with its number (per report date).
with numbered as (
    select id,
           created_at,
           row_number() over (
               partition by created_at::date order by created_at
           ) as rn
    from public.complaints
    where complaint_number is null
)
update public.complaints c
set complaint_number =
    'SS-' || to_char(n.created_at, 'YYMMDD') || '-' || lpad(n.rn::text, 3, '0')
from numbered n
where c.id = n.id;

-- Auto-assign a number to every new complaint.
create or replace function public.assign_complaint_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    day_count integer;
begin
    if new.complaint_number is null then
        -- Serialize concurrent inserts so the per-day counter can't collide.
        perform pg_advisory_xact_lock(hashtext('assign_complaint_number'));
        select count(*) + 1 into day_count
        from public.complaints
        where complaint_number like
            'SS-' || to_char(new.created_at, 'YYMMDD') || '-%';
        new.complaint_number :=
            'SS-' || to_char(new.created_at, 'YYMMDD') || '-' ||
            lpad(day_count::text, 3, '0');
    end if;
    return new;
end;
$$;

drop trigger if exists assign_complaint_number_on_insert on public.complaints;
create trigger assign_complaint_number_on_insert
    before insert on public.complaints
    for each row execute function public.assign_complaint_number();

create unique index if not exists complaints_number_unique
    on public.complaints (complaint_number)
    where complaint_number is not null;

-- -----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY — COMPLAINTS
-- -----------------------------------------------------------------------------
alter table public.complaints enable row level security;

-- Citizen: sees their own complaints.
drop policy if exists "complaints_select_citizen" on public.complaints;
create policy "complaints_select_citizen" on public.complaints
  for select
  using (auth.uid() = citizen_id);

-- Citizen: can also see ALL complaints (city map dashboard shows every
-- reported complaint with its status color, so citizens can see what is
-- happening around the city).
drop policy if exists "complaints_select_citizen_all" on public.complaints;
create policy "complaints_select_citizen_all" on public.complaints
  for select
  using (public.is_citizen());

-- Worker: sees complaints assigned to them (assigned_to holds their Worker ID).
-- Uses the security-definer helper so the policy never reads profiles under
-- RLS (avoids infinite recursion between the profiles and complaints policies).
drop policy if exists "complaints_select_worker" on public.complaints;
create policy "complaints_select_worker" on public.complaints
  for select
  using (
    public.is_worker()
    and public.complaints.assigned_to = public.worker_id_of_current_user()
  );

-- Head: sees everything (monitors the whole city).
drop policy if exists "complaints_select_head" on public.complaints;
create policy "complaints_select_head" on public.complaints
  for select
  using (public.is_head());

-- Citizen: can only insert complaints that belong to them.
drop policy if exists "complaints_insert_citizen" on public.complaints;
create policy "complaints_insert_citizen" on public.complaints
  for insert
  with check (auth.uid() = citizen_id);

-- Updates: citizen (own, no status change), worker (assigned), head (any).
-- Worker branch uses the security-definer helper to avoid RLS recursion.
drop policy if exists "complaints_update" on public.complaints;
create policy "complaints_update" on public.complaints
  for update
  using (
    auth.uid() = citizen_id
    or (public.is_worker()
        and public.complaints.assigned_to = public.worker_id_of_current_user())
    or public.is_head()
  )
  with check (
    auth.uid() = citizen_id
    or (public.is_worker()
        and public.complaints.assigned_to = public.worker_id_of_current_user())
    or public.is_head()
  );

-- Citizens may not flip their own complaint status (only workers/head can).
create or replace function public.prevent_citizen_status_change()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() = old.citizen_id and new.status is distinct from old.status then
    raise exception 'Citizens cannot change the status of their own complaint.';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_citizen_status_change on public.complaints;
create trigger prevent_citizen_status_change
  before update on public.complaints
  for each row execute function public.prevent_citizen_status_change();

-- -----------------------------------------------------------------------------
-- 5b. COLLECTION TASKS (head assigns → worker sees in their own app)
-- -----------------------------------------------------------------------------
create table if not exists public.tasks (
  id                   uuid primary key default gen_random_uuid(),
  title                text not null,
  description          text not null default '',
  latitude             double precision,
  longitude            double precision,
  worker_id            text,
  citizen_complaint_id uuid references public.complaints (id) on delete set null,
  assigned_at          timestamptz not null default now(),
  status               text not null default 'assigned',
  completed_at         timestamptz,
  proof_photo_url      text,
  proof_note           text,
  reviewed_by_head     boolean not null default false,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

alter table public.tasks drop constraint if exists tasks_status_check;
alter table public.tasks add constraint tasks_status_check
  check (status in ('assigned', 'en_route', 'collecting', 'completed', 'rejected', 'revoked'));

drop trigger if exists set_tasks_updated_at on public.tasks;
create trigger set_tasks_updated_at
  before update on public.tasks
  for each row execute function public.handle_updated_at();

alter table public.tasks enable row level security;

-- Head: can see/create/assign every task.
drop policy if exists "tasks_select_head" on public.tasks;
create policy "tasks_select_head" on public.tasks
  for select using (public.is_head());

drop policy if exists "tasks_insert_head" on public.tasks;
create policy "tasks_insert_head" on public.tasks
  for insert with check (public.is_head());

drop policy if exists "tasks_update_head" on public.tasks;
create policy "tasks_update_head" on public.tasks
  for update using (public.is_head()) with check (public.is_head());

drop policy if exists "tasks_delete_head" on public.tasks;
create policy "tasks_delete_head" on public.tasks
  for delete using (public.is_head());

-- Worker: sees only tasks assigned to their Worker ID, updates only their own.
drop policy if exists "tasks_select_worker" on public.tasks;
create policy "tasks_select_worker" on public.tasks
  for select
  using (
    public.is_worker()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.worker_id = public.tasks.worker_id
    )
  );

drop policy if exists "tasks_update_worker" on public.tasks;
create policy "tasks_update_worker" on public.tasks
  for update
  using (
    public.is_worker()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.worker_id = public.tasks.worker_id
    )
  )
  with check (
    public.is_worker()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.worker_id = public.tasks.worker_id
    )
  );

-- Workers may update status/proof fields but never re-assign the task to
-- someone else and never mark their own proof as reviewed by the Head.
create or replace function public.prevent_worker_task_tamper()
returns trigger
language plpgsql
as $$
begin
  if public.is_worker() and not public.is_head() then
    if new.worker_id is distinct from old.worker_id then
      raise exception 'Workers cannot reassign tasks.';
    end if;
    -- Workers may never MARK a proof as reviewed by the Head (that flag is
    -- set only by the Head). Clearing it to false is allowed — it happens
    -- when a worker restarts a rejected task and submits a new proof.
    if new.reviewed_by_head = true then
      raise exception 'Only the Head can review proofs.';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_worker_task_tamper on public.tasks;
create trigger prevent_worker_task_tamper
  before update on public.tasks
  for each row execute function public.prevent_worker_task_tamper();

-- Citizen: sees the task linked to their own complaint (for the proof photo).
drop policy if exists "tasks_select_citizen" on public.tasks;
create policy "tasks_select_citizen" on public.tasks
  for select
  using (
    exists (
      select 1 from public.complaints c
      where c.id = public.tasks.citizen_complaint_id
        and c.citizen_id = auth.uid()
    )
  );

-- -----------------------------------------------------------------------------
-- 5c. WORKER LIVE LOCATIONS (worker shares GPS → Head sees it in real time)
-- -----------------------------------------------------------------------------
-- One row per worker, keyed by their Worker ID (WK-XXXX). The worker app
-- upserts this row every few seconds while sharing; the Head reads all rows.
-- RLS lets a worker touch ONLY their own row and lets the Head read/delete
-- every row (delete is used when a worker is removed).
create table if not exists public.worker_locations (
  worker_id  text primary key,
  latitude   double precision not null,
  longitude  double precision not null,
  is_sharing boolean not null default false,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_worker_locations_updated_at on public.worker_locations;
create trigger set_worker_locations_updated_at
  before update on public.worker_locations
  for each row execute function public.handle_updated_at();

alter table public.worker_locations enable row level security;

-- Head: sees every worker's live location; may delete a row when removing a worker.
drop policy if exists "worker_locations_select_head" on public.worker_locations;
create policy "worker_locations_select_head" on public.worker_locations
  for select using (public.is_head());

-- Citizen: can read every worker's live location for the city map's
-- "Track Collection Vehicle" page (truck markers + on/off-duty status).
drop policy if exists "worker_locations_select_citizen" on public.worker_locations;
create policy "worker_locations_select_citizen" on public.worker_locations
  for select using (public.is_citizen());

drop policy if exists "worker_locations_delete_head" on public.worker_locations;
create policy "worker_locations_delete_head" on public.worker_locations
  for delete using (public.is_head());

-- Helper: returns the Worker ID of the currently signed-in user, or NULL.
-- security definer + search_path = public so it reads profiles DIRECTLY,
-- bypassing RLS on profiles entirely. (A plain EXISTS subquery inside the
-- policy runs under RLS too and can reject the row it needs — the classic
-- cause of "new row violates row-level security policy" on upsert.)
create or replace function public.worker_id_of_current_user()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select worker_id from public.profiles where id = auth.uid();
$$;

-- Worker: may upsert (insert/update) ONLY the row matching their own Worker ID,
-- so they can never overwrite another worker's position.
drop policy if exists "worker_locations_insert_own" on public.worker_locations;
create policy "worker_locations_insert_own" on public.worker_locations
  for insert
  with check (
    public.is_worker()
    and worker_id = public.worker_id_of_current_user()
  );

drop policy if exists "worker_locations_update_own" on public.worker_locations;
create policy "worker_locations_update_own" on public.worker_locations
  for update
  using (
    public.is_worker()
    and worker_id = public.worker_id_of_current_user()
  )
  with check (
    public.is_worker()
    and worker_id = public.worker_id_of_current_user()
  );

-- Server-side upsert used by the worker app. The Worker ID is read from the
-- caller's OWN profile (auth.uid()) — the client never sends a Worker ID, so
-- a mismatch is impossible and a worker can never write another worker's row.
create or replace function public.share_worker_location(
  p_lat double precision,
  p_lng double precision
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_worker_id text;
begin
  select worker_id into v_worker_id
  from public.profiles
  where id = auth.uid();

  if v_worker_id is null then
    raise exception 'No Worker ID on this account yet. Ask your Head to generate one.';
  end if;

  insert into public.worker_locations (worker_id, latitude, longitude, is_sharing)
  values (v_worker_id, p_lat, p_lng, true)
  on conflict (worker_id)
  do update set latitude = excluded.latitude,
                longitude = excluded.longitude,
                is_sharing = true,
                updated_at = now();
end;
$$;

create or replace function public.stop_worker_location()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.worker_locations
  set is_sharing = false
  where worker_id = (
    select worker_id from public.profiles where id = auth.uid()
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- 6. STORAGE — complaint photos
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('complaint-photos', 'complaint-photos', true)
on conflict (id) do nothing;

-- Authenticated users may upload only into their own folder: <uid>/<file>.
drop policy if exists "complaint_photos_insert_own" on storage.objects;
create policy "complaint_photos_insert_own" on storage.objects
  for insert
  with check (
    bucket_id = 'complaint-photos'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "complaint_photos_update_own" on storage.objects;
create policy "complaint_photos_update_own" on storage.objects
  for update
  using (
    bucket_id = 'complaint-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "complaint_photos_delete_own" on storage.objects;
create policy "complaint_photos_delete_own" on storage.objects
  for delete
  using (
    bucket_id = 'complaint-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- -----------------------------------------------------------------------------
-- 7. GRANTS (PostgREST authenticates as the "authenticated" role)
-- -----------------------------------------------------------------------------
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.complaints to authenticated;
grant select, insert, update, delete on public.tasks to authenticated;
grant select, insert, update, delete on public.worker_locations to authenticated;
revoke execute on function public.share_worker_location(double precision, double precision) from public, anon;
grant execute on function public.share_worker_location(double precision, double precision) to authenticated;
revoke execute on function public.stop_worker_location() from public, anon;
grant execute on function public.stop_worker_location() to authenticated;

-- =============================================================================
-- 8a. DIAGNOSTICS (run if location sharing still fails)
-- -----------------------------------------------------------------------------
-- Sharing now goes through the server-side function share_worker_location(),
-- which reads the Worker ID from the caller's own profile. The only reasons
-- it can fail:
--   1) The worker account has NO worker_id set on its profile row, or
--   2) The worker's profile role is not exactly 'worker'.
-- Run these to see exactly what the database holds:
--
--   -- 1) All profiles: check role and worker_id for your worker account
--   select email, role, worker_id, vehicle_number
--   from public.profiles order by created_at desc;
--
--   -- 2) Location rows (should fill up while a worker shares)
--   select * from public.worker_locations order by updated_at desc;
--
--   -- 3) If worker_id is null on the worker's row, assign it (or use the
--   --    Head app's Generate Worker ID):
--   --    update public.profiles set worker_id = 'WK-1001'
--   --    where email = 'worker1@example.com';
--
--   -- 4) Confirm the function exists:
--   select proname from pg_proc
--   where proname in ('share_worker_location', 'stop_worker_location');
--
-- =============================================================================
-- 8. CREATE WORKER / HEAD ACCOUNTS (do this in the Supabase Dashboard)
-- -----------------------------------------------------------------------------
-- 1. Supabase Dashboard → Authentication → Users → Add user.
--    Enter the email and a temporary password. Do NOT set a role here.
--    The handle_new_user trigger (section 2) auto-creates the profile row
--    with role = 'citizen' as soon as the auth user exists.
--
-- 2. Assign the role from a TRUSTED environment (SQL editor / service role),
--    e.g. replace the email below and run:
--
--    update public.profiles
--    set role = 'worker'
--    where email = 'worker1@example.com';
--
--    update public.profiles
--    set role = 'head'
--    where email = 'head1@example.com';
--
--    The Flutter client can NEVER set a worker/head role on itself:
--      * profiles_update_own policy only lets users touch their own row,
--      * prevent_self_role_change trigger rejects role/worker_id/vehicle
--        changes when auth.uid() = the row being updated.
--
-- 3. Workers can additionally be assigned a Worker ID + vehicle by the Head
--    from the Head app (Head → Workers → Generate Worker ID), or directly:
--
--    update public.profiles
--    set worker_id = 'WK-1001', vehicle_number = 'GJ-18-WM-1024'
--    where email = 'worker1@example.com';
-- =============================================================================
-- PUSH NOTIFICATIONS (FCM) — device tokens
-- -----------------------------------------------------------------------------
-- Each signed-in device stores its Firebase Cloud Messaging token here so the
-- app (or a future server-side sender) can target push notifications at a
-- specific user. One row per device token; the app upserts on login and on
-- token refresh. Idempotent — safe to re-run with the rest of this file.
-- =============================================================================

create table if not exists public.device_tokens (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    token text not null unique,
    platform text not null default 'android',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

-- A user may read, insert, update and delete their own tokens (the app upserts
-- on login / token refresh). Any authenticated user may read all tokens so the
-- app or a future Edge Function can look up a recipient's token.
drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own" on public.device_tokens
    for select using (auth.uid() = user_id);
drop policy if exists "device_tokens_select_all" on public.device_tokens;
create policy "device_tokens_select_all" on public.device_tokens
    for select using (auth.role() = 'authenticated');
drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own" on public.device_tokens
    for insert with check (auth.uid() = user_id);
drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own" on public.device_tokens
    for update using (auth.uid() = user_id);
drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own" on public.device_tokens
    for delete using (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- In-app notification history. Every push sent through the send-notification
-- Edge Function is stored here per recipient, so users can view and clear
-- their notification history inside the app (Profile -> Notifications). The
-- Edge Function writes with the service-role key (bypasses RLS); the app can
-- only read/update/delete its own rows.
-- =============================================================================

create table if not exists public.notifications (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    body text not null,
    route text,
    is_read boolean not null default false,
    created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
    for select using (auth.uid() = user_id);
drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
    for update using (auth.uid() = user_id);
drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own" on public.notifications
    for delete using (auth.uid() = user_id);

create index if not exists notifications_user_idx
    on public.notifications (user_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Problem reports (Help & Support -> "Report a Problem").
-- One report per user — enforced both by the unique constraint and the page.
-- =============================================================================

create table if not exists public.problem_reports (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    message text not null,
    created_at timestamptz not null default now(),
    unique (user_id)
);

alter table public.problem_reports enable row level security;

drop policy if exists "problem_reports_select_own" on public.problem_reports;
create policy "problem_reports_select_own" on public.problem_reports
    for select using (auth.uid() = user_id);
drop policy if exists "problem_reports_insert_own" on public.problem_reports;
create policy "problem_reports_insert_own" on public.problem_reports
    for insert with check (auth.uid() = user_id);

-- =============================================================================

