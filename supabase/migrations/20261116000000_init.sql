-- Setline: initial schema.
--
-- Principles
--   * Every table has row-level security (RLS). A user only touches rows for
--     projects they belong to, and only channels their role can see.
--   * Anything with more than one step (create project, join, send frame,
--     approve frame) is a Postgres function, so no client can skip a step.
--     A future web review page calls the same functions.
--   * A wrapped project rejects every write, enforced by triggers, except the
--     producer reopening it.

-- ---------------------------------------------------------------------------
-- Types
-- ---------------------------------------------------------------------------
create type public.project_role as enum
  ('producer', 'photographer', 'digi_tech', 'crew', 'glam', 'agency', 'client', 'talent');
create type public.project_status as enum ('prep', 'live', 'wrapped');
create type public.frame_status as enum ('pending', 'approved', 'alt');
create type public.attachment_kind as enum ('image', 'video', 'file');

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  full_name   text not null default '',
  avatar_path text,
  phone       text,
  created_at  timestamptz not null default now()
);

create table public.projects (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,                       -- client / brand
  job               text,
  shoot_date        date,
  crew_call         time,
  timezone          text not null default 'America/New_York',
  location          text,
  location_notes    text,
  status            public.project_status not null default 'prep',
  recording_enabled boolean not null default false,      -- walkie recording + transcripts (later)
  created_by        uuid not null references public.profiles (id),
  created_at        timestamptz not null default now(),
  wrapped_at        timestamptz
);

create table public.project_members (
  project_id       uuid not null references public.projects on delete cascade,
  user_id          uuid not null references public.profiles on delete cascade,
  role             public.project_role not null,
  department_title text,                                  -- e.g. "1st Assistant"
  joined_at        timestamptz not null default now(),
  primary key (project_id, user_id)
);
create index on public.project_members (user_id);

-- One invite per role, so the link decides the role. Replaces projects.invite_code.
create table public.project_invites (
  code       text primary key,                            -- e.g. HLD-7Q4K-CR
  project_id uuid not null references public.projects on delete cascade,
  role       public.project_role not null check (role <> 'producer'),
  created_by uuid not null references public.profiles (id),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz
);
create index on public.project_invites (project_id);

create table public.channels (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references public.projects on delete cascade,
  slug          text not null,
  name          text not null,
  description   text,
  visible_roles public.project_role[] not null,           -- producer + photographer always see every channel
  is_client_visible boolean generated always as
                (visible_roles && array['agency', 'client']::public.project_role[]) stored,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now(),
  unique (project_id, slug),
  unique (id, project_id)
);

create table public.shots (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references public.projects on delete cascade,
  number            int not null,
  name              text not null,
  is_done           boolean not null default false,
  done_by           uuid references public.profiles (id),
  done_at           timestamptz,
  approved_frame_id uuid,                                  -- set only by approve_frame()
  sort_order        int not null default 0,
  created_at        timestamptz not null default now()
);
create index on public.shots (project_id, sort_order);

create table public.frames (
  id           uuid primary key default gen_random_uuid(),
  project_id   uuid not null references public.projects on delete cascade,
  shot_id      uuid references public.shots on delete set null,
  file_path    text not null,                              -- original, private bucket
  preview_path text,                                       -- compressed copy for the card
  frame_code   text not null,                              -- e.g. HLD_0142
  status       public.frame_status not null default 'pending',
  is_favorite  boolean not null default false,
  sent_by      uuid not null references public.profiles (id),
  sent_at      timestamptz not null default now(),
  approved_by  uuid references public.profiles (id),
  approved_at  timestamptz,
  unique (project_id, frame_code)
);
create index on public.frames (project_id, sent_at desc);
create index on public.frames (shot_id);
alter table public.shots
  add constraint shots_approved_frame_fk foreign key (approved_frame_id)
  references public.frames (id) on delete set null;

create table public.messages (
  id                      uuid primary key default gen_random_uuid(),
  project_id              uuid not null,
  channel_id              uuid not null,
  sender_id               uuid references public.profiles (id),
  body                    text,
  attachment_path         text,
  attachment_preview_path text,
  attachment_type         public.attachment_kind,
  attachment_name         text,
  frame_id                uuid references public.frames on delete set null,
  is_system               boolean not null default false,
  created_at              timestamptz not null default now(),
  foreign key (channel_id, project_id) references public.channels (id, project_id) on delete cascade,
  check (is_system or sender_id is not null),
  check (body is not null or attachment_path is not null)
);
create index on public.messages (channel_id, created_at desc);

create table public.channel_reads (
  channel_id   uuid not null references public.channels on delete cascade,
  user_id      uuid not null references public.profiles on delete cascade,
  last_read_at timestamptz not null default now(),
  primary key (channel_id, user_id)
);

create table public.frame_comments (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects on delete cascade,
  frame_id   uuid not null references public.frames on delete cascade,
  author_id  uuid not null references public.profiles (id),
  body       text not null check (length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
create index on public.frame_comments (frame_id, created_at);

create table public.ptt_channels (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references public.projects on delete cascade,
  name          text not null,
  allowed_roles public.project_role[] not null,
  livekit_room  text generated always as ('ptt_' || id::text) stored,
  created_at    timestamptz not null default now()
);

create table public.ptt_transmissions (
  id             uuid primary key default gen_random_uuid(),
  project_id     uuid not null references public.projects on delete cascade,
  ptt_channel_id uuid not null references public.ptt_channels on delete cascade,
  speaker_id     uuid not null references public.profiles (id),
  started_at     timestamptz not null,
  duration_ms    int not null check (duration_ms >= 0),
  latency_ms     int,                                      -- dev builds only
  recording_path text,                                     -- later, behind projects.recording_enabled
  transcript     text                                      -- later
);
create index on public.ptt_transmissions (ptt_channel_id, started_at desc);

create table public.schedule_items (
  id         uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects on delete cascade,
  time       time not null,
  label      text not null,
  sort_order int not null default 0
);
create index on public.schedule_items (project_id, time);

-- Expo push tokens, one row per device.
create table public.push_tokens (
  token      text primary key,
  user_id    uuid not null references public.profiles on delete cascade,
  platform   text not null check (platform in ('ios', 'android')),
  updated_at timestamptz not null default now()
);
create index on public.push_tokens (user_id);

-- ---------------------------------------------------------------------------
-- Permission helpers. SECURITY DEFINER so policies can call them without
-- recursing into RLS on project_members.
-- ---------------------------------------------------------------------------
create function public.my_role(p_project uuid) returns public.project_role
language sql stable security definer set search_path = public as $$
  select role from project_members where project_id = p_project and user_id = auth.uid()
$$;

create function public.is_member(p_project uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from project_members where project_id = p_project and user_id = auth.uid())
$$;

-- The permission table from the brief, in one place.
create function public.role_can(p_project uuid, p_perm text) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(
    case p_perm
      when 'walkie'      then r in ('producer', 'photographer', 'digi_tech', 'crew', 'glam')
      when 'approve'     then r in ('producer', 'photographer', 'agency', 'client')
      when 'send_frames' then r in ('producer', 'photographer', 'digi_tech')
      when 'view_frames' then r in ('producer', 'photographer', 'digi_tech', 'agency', 'client')
      when 'view_shots'  then r <> 'talent'
      when 'edit_shots'  then r in ('producer', 'photographer', 'crew')
      when 'manage'      then r = 'producer'
      else false
    end, false)
  from (select public.my_role(p_project) as r) x
$$;

create function public.can_see_channel(p_channel uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from channels c
    join project_members m on m.project_id = c.project_id and m.user_id = auth.uid()
    where c.id = p_channel
      and (m.role in ('producer', 'photographer') or m.role = any (c.visible_roles))
  )
$$;

create function public.can_use_ptt(p_ptt uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from ptt_channels pc
    join project_members m on m.project_id = pc.project_id and m.user_id = auth.uid()
    where pc.id = p_ptt
      and m.role in ('producer', 'photographer', 'digi_tech', 'crew', 'glam')
      and (m.role in ('producer', 'photographer') or m.role = any (pc.allowed_roles))
  )
$$;

create function public.shares_project_with(p_user uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from project_members a join project_members b on a.project_id = b.project_id
    where a.user_id = auth.uid() and b.user_id = p_user
  )
$$;

-- ---------------------------------------------------------------------------
-- Wrapped projects are read only (except reopening, and read receipts).
-- ---------------------------------------------------------------------------
create function public.reject_if_wrapped() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  pid uuid := case when tg_op = 'DELETE' then old.project_id else new.project_id end;
begin
  if exists (select 1 from projects where id = pid and status = 'wrapped') then
    raise exception 'This project is wrapped and read only.' using errcode = 'P0001';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;

do $$
declare t text;
begin
  foreach t in array array['project_members', 'project_invites', 'channels', 'messages', 'shots',
                           'frames', 'frame_comments', 'ptt_channels', 'ptt_transmissions', 'schedule_items']
  loop
    execute format('create trigger %I before insert or update or delete on public.%I
                    for each row execute function public.reject_if_wrapped()', t || '_not_wrapped', t);
  end loop;
end $$;

create function public.guard_project_update() returns trigger
language plpgsql as $$
begin
  if old.status = 'wrapped' then
    -- The only allowed change to a wrapped project is reopening it.
    if new.status = 'wrapped'
       or (to_jsonb(new) - 'status' - 'wrapped_at') <> (to_jsonb(old) - 'status' - 'wrapped_at') then
      raise exception 'This project is wrapped. Reopen it before making changes.' using errcode = 'P0001';
    end if;
    new.wrapped_at := null;
  elsif new.status = 'wrapped' then
    new.wrapped_at := now();
  end if;
  return new;
end $$;
create trigger projects_guard before update on public.projects
  for each row execute function public.guard_project_update();

-- ---------------------------------------------------------------------------
-- New users get a profile.
-- ---------------------------------------------------------------------------
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Multi-step actions (the only way to do these things).
-- ---------------------------------------------------------------------------

-- Create a project: you become producer; default channels and walkie are added.
create function public.create_project(
  p_name text, p_job text default null, p_shoot_date date default null,
  p_crew_call time default null, p_location text default null,
  p_timezone text default 'America/New_York'
) returns uuid
language plpgsql security definer set search_path = public as $$
declare pid uuid;
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  insert into projects (name, job, shoot_date, crew_call, location, timezone, created_by)
  values (p_name, p_job, p_shoot_date, p_crew_call, p_location, p_timezone, auth.uid())
  returning id into pid;

  insert into project_members (project_id, user_id, role, department_title)
  values (pid, auth.uid(), 'producer', 'Producer');

  insert into channels (project_id, slug, name, description, visible_roles, sort_order) values
    (pid, 'general',       'general',       'Everyone on the job',     array['producer','photographer','digi_tech','crew','glam','agency','client','talent']::project_role[], 0),
    (pid, 'crew',          'crew',          'Camera, grip and electric', array['producer','photographer','digi_tech','crew']::project_role[], 1),
    (pid, 'glam',          'glam',          'Hair and makeup',         array['producer','photographer','glam']::project_role[], 2),
    (pid, 'wardrobe',      'wardrobe',      'Pulls, fittings, steaming', array['producer','photographer','glam']::project_role[], 3),
    (pid, 'digi-tech',     'digi-tech',     'Capture, backups, naming', array['producer','photographer','digi_tech','crew']::project_role[], 4),
    (pid, 'client-review', 'client-review', 'Frames for approval',     array['producer','photographer','digi_tech','agency','client']::project_role[], 5),
    (pid, 'talent',        'talent',        'Talent and production',   array['producer','photographer','talent']::project_role[], 6);

  insert into ptt_channels (project_id, name, allowed_roles)
  values (pid, 'All crew', array['producer','photographer','digi_tech','crew','glam']::project_role[]);

  return pid;
end $$;

-- Make an invite link for one role. Producer only.
create function public.create_invite(p_project uuid, p_role public.project_role) returns text
language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  if not role_can(p_project, 'manage') then raise exception 'Only the producer can invite.' using errcode = '42501'; end if;
  if p_role = 'producer' then raise exception 'Invite links cannot make producers.'; end if;
  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (select 1 from project_invites where code = v_code);
  end loop;
  insert into project_invites (code, project_id, role, created_by) values (v_code, p_project, p_role, auth.uid());
  return v_code;
end $$;

-- Join with an invite code. Existing members keep their current role.
create function public.join_project(p_code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare inv project_invites;
begin
  if auth.uid() is null then raise exception 'Sign in first.' using errcode = '42501'; end if;
  select * into inv from project_invites
   where code = upper(trim(p_code)) and revoked_at is null and (expires_at is null or expires_at > now());
  if not found then raise exception 'That invite code is not valid.'; end if;
  insert into project_members (project_id, user_id, role)
  values (inv.project_id, auth.uid(), inv.role)
  on conflict (project_id, user_id) do nothing;
  return inv.project_id;
end $$;

-- Send a frame to client-review (file is uploaded to storage first).
create function public.send_frame(
  p_project uuid, p_shot uuid, p_file_path text, p_preview_path text, p_frame_code text
) returns public.frames
language plpgsql security definer set search_path = public as $$
declare f frames; s shots; ch uuid;
begin
  if not role_can(p_project, 'send_frames') then raise exception 'Your role cannot send frames.' using errcode = '42501'; end if;
  if p_file_path not like p_project::text || '/frames/%' then raise exception 'File is not in this project''s folder.'; end if;
  if p_shot is not null then
    select * into s from shots where id = p_shot and project_id = p_project;
    if not found then raise exception 'That look is not in this project.'; end if;
  end if;
  insert into frames (project_id, shot_id, file_path, preview_path, frame_code, sent_by)
  values (p_project, p_shot, p_file_path, p_preview_path, p_frame_code, auth.uid())
  returning * into f;
  select id into ch from channels where project_id = p_project and slug = 'client-review';
  insert into messages (project_id, channel_id, sender_id, body, frame_id, is_system)
  values (p_project, ch, auth.uid(),
          format('%s sent %s%s', split_part((select full_name from profiles where id = auth.uid()), ' ', 1), f.frame_code,
                 case when s.id is null then '' else format(' for Look %s', lpad(s.number::text, 2, '0')) end),
          f.id, true);
  return f;
end $$;

-- Approve a frame, all in one transaction:
--   1. frame -> approved   2. other pending frames for the same look -> alt
--   3. look checked off    4. system message in client-review
create function public.approve_frame(p_frame uuid) returns public.frames
language plpgsql security definer set search_path = public as $$
declare f frames; s shots; ch uuid; who text;
begin
  select * into f from frames where id = p_frame for update;
  if not found or not is_member(f.project_id) then raise exception 'Frame not found.'; end if;
  if not role_can(f.project_id, 'approve') then raise exception 'Your role cannot approve frames.' using errcode = '42501'; end if;
  if f.status <> 'pending' then raise exception 'Only frames waiting for approval can be approved.'; end if;
  -- the wrapped check happens in the frames trigger below

  update frames set status = 'approved', approved_by = auth.uid(), approved_at = now()
   where id = f.id returning * into f;

  if f.shot_id is not null then
    update frames set status = 'alt' where shot_id = f.shot_id and id <> f.id and status = 'pending';
    update shots set is_done = true, done_by = auth.uid(), done_at = now(), approved_frame_id = f.id
     where id = f.shot_id returning * into s;
  end if;

  select split_part(full_name, ' ', 1) into who from profiles where id = auth.uid();
  select id into ch from channels where project_id = f.project_id and slug = 'client-review';
  insert into messages (project_id, channel_id, sender_id, body, frame_id, is_system)
  values (f.project_id, ch, auth.uid(),
          format('%s approved %s.%s', who, f.frame_code,
                 case when s.id is null then '' else format(' Look %s checked off.', lpad(s.number::text, 2, '0')) end),
          f.id, true);
  return f;
end $$;

-- Wrap / reopen. Producer only.
create function public.set_wrapped(p_project uuid, p_wrapped boolean) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not role_can(p_project, 'manage') then raise exception 'Only the producer can wrap or reopen.' using errcode = '42501'; end if;
  update projects set status = case when p_wrapped then 'wrapped' else 'live' end::project_status where id = p_project;
end $$;

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------
alter table public.profiles          enable row level security;
alter table public.projects          enable row level security;
alter table public.project_members   enable row level security;
alter table public.project_invites   enable row level security;
alter table public.channels          enable row level security;
alter table public.messages          enable row level security;
alter table public.channel_reads     enable row level security;
alter table public.shots             enable row level security;
alter table public.frames            enable row level security;
alter table public.frame_comments    enable row level security;
alter table public.ptt_channels      enable row level security;
alter table public.ptt_transmissions enable row level security;
alter table public.schedule_items    enable row level security;
alter table public.push_tokens       enable row level security;

-- profiles: see yourself and people you work with; edit only yourself
create policy profiles_select on public.profiles for select
  using (id = auth.uid() or shares_project_with(id));
create policy profiles_update on public.profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- projects: members read; producer edits details. Create/wrap go through functions.
create policy projects_select on public.projects for select using (is_member(id));
create policy projects_update on public.projects for update
  using (role_can(id, 'manage')) with check (role_can(id, 'manage'));

-- members: everyone on the project sees the people list
create policy members_select on public.project_members for select using (is_member(project_id));
create policy members_update on public.project_members for update
  using (role_can(project_id, 'manage')) with check (role_can(project_id, 'manage'));
create policy members_delete on public.project_members for delete
  using (role_can(project_id, 'manage') or user_id = auth.uid());

-- invites: producer only
create policy invites_select on public.project_invites for select using (role_can(project_id, 'manage'));
create policy invites_update on public.project_invites for update
  using (role_can(project_id, 'manage')) with check (role_can(project_id, 'manage'));

-- channels: only the ones your role can see; producer manages
create policy channels_select on public.channels for select using (can_see_channel(id));
create policy channels_insert on public.channels for insert with check (role_can(project_id, 'manage'));
create policy channels_update on public.channels for update
  using (role_can(project_id, 'manage')) with check (role_can(project_id, 'manage'));
create policy channels_delete on public.channels for delete
  using (role_can(project_id, 'manage') and slug not in ('general', 'client-review'));

-- messages: read and post in channels you can see; never post as system or as someone else
create policy messages_select on public.messages for select using (can_see_channel(channel_id));
create policy messages_insert on public.messages for insert
  with check (can_see_channel(channel_id) and sender_id = auth.uid() and not is_system and frame_id is null);
create policy messages_delete on public.messages for delete
  using (sender_id = auth.uid() and not is_system);

-- read receipts: your own rows only (still allowed after wrap)
create policy reads_all on public.channel_reads for all
  using (user_id = auth.uid() and can_see_channel(channel_id))
  with check (user_id = auth.uid() and can_see_channel(channel_id));

-- shots: everyone but talent reads; producer, photographer and crew edit
create policy shots_select on public.shots for select using (role_can(project_id, 'view_shots'));
create policy shots_insert on public.shots for insert with check (role_can(project_id, 'edit_shots'));
create policy shots_update on public.shots for update
  using (role_can(project_id, 'edit_shots')) with check (role_can(project_id, 'edit_shots'));
create policy shots_delete on public.shots for delete using (role_can(project_id, 'edit_shots'));
-- approved_frame_id is only ever set by approve_frame()
revoke update on public.shots from authenticated, anon;
grant update (number, name, is_done, done_by, done_at, sort_order) on public.shots to authenticated;

-- frames: client-review roles read; approvers can only flip the favorite flag.
-- Sending and approving go through send_frame() and approve_frame().
create policy frames_select on public.frames for select using (role_can(project_id, 'view_frames'));
create policy frames_update on public.frames for update
  using (role_can(project_id, 'approve')) with check (role_can(project_id, 'approve'));
create policy frames_delete on public.frames for delete using (role_can(project_id, 'manage'));
revoke insert, update on public.frames from authenticated, anon;
grant update (is_favorite) on public.frames to authenticated;

-- frame comments: client-review roles read; approvers comment
create policy fcomments_select on public.frame_comments for select using (role_can(project_id, 'view_frames'));
create policy fcomments_insert on public.frame_comments for insert
  with check (role_can(project_id, 'approve') and author_id = auth.uid()
              and exists (select 1 from frames f where f.id = frame_id and f.project_id = frame_comments.project_id));
create policy fcomments_delete on public.frame_comments for delete using (author_id = auth.uid());

-- walkie channels and log: walkie roles only
create policy ptt_select on public.ptt_channels for select using (can_use_ptt(id));
create policy ptt_manage on public.ptt_channels for all
  using (role_can(project_id, 'manage')) with check (role_can(project_id, 'manage'));
create policy pttx_select on public.ptt_transmissions for select using (can_use_ptt(ptt_channel_id));
create policy pttx_insert on public.ptt_transmissions for insert
  with check (speaker_id = auth.uid() and can_use_ptt(ptt_channel_id)
              and exists (select 1 from ptt_channels pc where pc.id = ptt_channel_id and pc.project_id = ptt_transmissions.project_id));

-- schedule: everyone reads; producer edits
create policy sched_select on public.schedule_items for select using (is_member(project_id));
create policy sched_manage on public.schedule_items for all
  using (role_can(project_id, 'manage')) with check (role_can(project_id, 'manage'));

-- push tokens: your own devices only
create policy push_all on public.push_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Storage: one private bucket, organised by project.
--   {project_id}/chat/{channel_id}/{file}
--   {project_id}/frames/{file}
--   {project_id}/avatars/... is not used; avatars live under avatars/{user_id}/
-- The app only ever shows short-lived signed URLs.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public) values ('media', 'media', false)
on conflict (id) do nothing;

create function public.storage_can(p_name text, p_write boolean) returns boolean
language plpgsql stable security definer set search_path = public as $$
declare parts text[] := string_to_array(p_name, '/'); pid uuid; cid uuid;
begin
  pid := parts[1]::uuid;
  if not is_member(pid) then return false; end if;
  if p_write and exists (select 1 from projects where id = pid and status = 'wrapped') then return false; end if;
  if parts[2] = 'chat' then
    cid := parts[3]::uuid;
    return exists (select 1 from channels where id = cid and project_id = pid) and can_see_channel(cid);
  elsif parts[2] = 'frames' then
    return role_can(pid, case when p_write then 'send_frames' else 'view_frames' end);
  end if;
  return false;
exception when others then
  return false;   -- malformed path
end $$;

create policy media_read on storage.objects for select to authenticated
  using (bucket_id = 'media' and storage_can(name, false));
create policy media_write on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and storage_can(name, true));

-- ---------------------------------------------------------------------------
-- Realtime: these tables stream changes to the app (RLS still applies).
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table
  public.messages, public.frames, public.frame_comments, public.shots,
  public.projects, public.project_members, public.schedule_items, public.ptt_transmissions;
