-- Sample data: the "Halden Skincare" shoot from the prototype.
--
-- Creates 11 sample people (one per role, plus extra crew), one live project
-- dated today, its channels, messages, shot list, frames, schedule and walkie log.
--
-- Sample logins: <first name>@halden.example, password "setline-demo".
-- These are for testing only. Delete them before real shoots (README explains how).

-- ---------------------------------------------------------------------------
-- People
-- ---------------------------------------------------------------------------
create temp table seed_people (
  id uuid, email text, full_name text, role public.project_role, title text
);

insert into seed_people values
  ('10000000-0000-4000-8000-000000000001', 'maya@halden.example',  'Maya Okafor', 'producer',     'Producer'),
  ('10000000-0000-4000-8000-000000000002', 'theo@halden.example',  'Theo Lind',   'photographer', 'Photographer'),
  ('10000000-0000-4000-8000-000000000003', 'rafi@halden.example',  'Rafi Mendez', 'digi_tech',    'Digital tech'),
  ('10000000-0000-4000-8000-000000000004', 'jonah@halden.example', 'Jonah Pike',  'crew',         '1st Assistant'),
  ('10000000-0000-4000-8000-000000000005', 'dee@halden.example',   'Dee Alvarez', 'crew',         'Gaffer'),
  ('10000000-0000-4000-8000-000000000006', 'sun@halden.example',   'Sun Park',    'crew',         'Key grip'),
  ('10000000-0000-4000-8000-000000000007', 'lena@halden.example',  'Lena Sato',   'glam',         'Hair & makeup'),
  ('10000000-0000-4000-8000-000000000008', 'priya@halden.example', 'Priya Nair',  'glam',         'Wardrobe stylist'),
  ('10000000-0000-4000-8000-000000000009', 'carla@halden.example', 'Carla Voss',  'agency',       'Art director, Northfold'),
  ('10000000-0000-4000-8000-000000000010', 'erin@halden.example',  'Erin Shaw',   'client',       'Brand manager, Halden'),
  ('10000000-0000-4000-8000-000000000011', 'ama@halden.example',   'Ama Boateng', 'talent',       'Talent');

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
select '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated', email,
       extensions.crypt('setline-demo', extensions.gen_salt('bf')), now(),
       '{"provider":"email","providers":["email"]}', jsonb_build_object('full_name', full_name), now(), now(),
       '', '', '', ''
from seed_people;

insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select gen_random_uuid(), id, id::text, jsonb_build_object('sub', id::text, 'email', email), 'email', now(), now(), now()
from seed_people;

-- (profiles are created by the on_auth_user_created trigger)

-- ---------------------------------------------------------------------------
-- Project, created through the real function so it gets the default channels
-- ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', false);

create temp table seed_ids (k text primary key, id uuid);
insert into seed_ids
select 'project', public.create_project(
  'Halden Skincare', 'Spring Serum Launch', current_date, '07:00',
  'Studio B, 548 W 28th St, New York, NY');

update public.projects set status = 'live', location_notes = 'Freight elevator on 28th. Load in by 6:45.'
where id = (select id from seed_ids where k = 'project');

insert into public.project_members (project_id, user_id, role, department_title)
select (select id from seed_ids where k = 'project'), id, role, title
from seed_people where role <> 'producer';

-- extra walkie channels
insert into public.ptt_channels (project_id, name, allowed_roles)
select (select id from seed_ids where k = 'project'), x.name, x.roles::public.project_role[]
from (values ('G&E', '{producer,photographer,crew}'), ('Glam', '{producer,photographer,glam}')) x(name, roles);

-- ---------------------------------------------------------------------------
-- Schedule and shot list
-- ---------------------------------------------------------------------------
insert into public.schedule_items (project_id, time, label, sort_order)
select (select id from seed_ids where k = 'project'), t::time, label, n
from (values (0, '07:00', 'Crew call'), (1, '08:00', 'Talent call, glam'), (2, '09:30', 'Looks 01 to 02, product'),
             (3, '11:00', 'Looks 03 to 04, Ama'), (4, '12:30', 'Lunch'), (5, '13:30', 'Looks 05 to 07'),
             (6, '16:00', 'Look 08, social vertical'), (7, '18:00', 'Wrap')) s(n, t, label);

insert into public.shots (project_id, number, name, sort_order)
select (select id from seed_ids where k = 'project'), n, name, n
from (values (1, 'Serum hero bottle'), (2, 'Dropper in hand'), (3, 'Ama close-up, dewy skin'), (4, 'Ama holding serum'),
             (5, 'Texture swatch'), (6, 'Full line flat lay'), (7, 'Bathroom shelf'), (8, 'Social vertical 9:16')) s(n, name);

-- ---------------------------------------------------------------------------
-- Chat messages (times are today, New York time)
-- ---------------------------------------------------------------------------
create or replace function pg_temp.at(t text) returns timestamptz language sql as $$
  select (current_date + t::time) at time zone 'America/New_York'
$$;

insert into public.messages (project_id, channel_id, sender_id, body, attachment_path, attachment_type, attachment_name, created_at)
select c.project_id, c.id, p.id, m.body, m.path, m.kind::public.attachment_kind, m.fname, pg_temp.at(m.t)
from (values
  ('general',   'maya',  '06:41', 'Morning all. Studio B, freight elevator is on 28th. Coffee is up.', null, null, null),
  ('general',   'maya',  '06:42', 'Final call sheet.', 'SAMPLE/Halden_callsheet_v3.pdf', 'file', 'Halden_callsheet_v3.pdf'),
  ('general',   'erin',  '09:15', 'Hi everyone, Erin from Halden. Excited for today.', null, null, null),
  ('general',   'maya',  '11:40', 'Lunch at 12:30 in the back lounge.', null, null, null),
  ('crew',      'jonah', '07:10', 'Tethered and live. Heads on stands 1 to 3.', null, null, null),
  ('crew',      'dee',   '07:24', 'Swapping key to the 3'' octa for Look 01.', null, null, null),
  ('crew',      'theo',  '11:46', '100 macro for Look 05 next. Clear the table.', null, null, null),
  ('glam',      'lena',  '07:35', 'Ama in the chair at 8. Dewy skin, no shimmer per agency.', null, null, null),
  ('glam',      'lena',  '11:20', 'Touch up before Look 04, 5 minutes.', null, null, null),
  ('glam',      'priya', '11:31', 'Steamer is in the hallway. Please don''t unplug it.', null, null, null),
  ('wardrobe',  'priya', '07:20', 'Robe options are on the rack, cream vs oat.', null, null, null),
  ('wardrobe',  'maya',  '07:28', 'Oat. Client approved yesterday.', null, null, null),
  ('digi-tech', 'rafi',  '07:45', 'Session is HLD_Spring26. Files are HLD_####.', null, null, null),
  ('digi-tech', 'rafi',  '10:40', 'Card 1 backed up to both drives.', null, null, null),
  ('digi-tech', 'jonah', '10:41', 'Copy.', null, null, null),
  ('client-review', 'carla', '10:22', 'Love the highlight on the cap.', null, null, null),
  ('client-review', 'rafi',  '11:49', 'Look 04 options coming in now.', null, null, null),
  ('talent',    'maya',  '08:10', 'Ama, lunch is at 12:30. Any food needs?', null, null, null),
  ('talent',    'ama',   '08:12', 'Vegetarian, thank you!', null, null, null)
) m(slug, who, t, body, path, kind, fname)
join public.channels c on c.slug = m.slug and c.project_id = (select id from seed_ids where k = 'project')
join seed_people p on p.email = m.who || '@halden.example';

-- the sample PDF path points at the project folder
update public.messages set attachment_path = replace(attachment_path, 'SAMPLE', project_id::text)
where attachment_path like 'SAMPLE/%';

-- ---------------------------------------------------------------------------
-- Frames: sent and approved through the real functions, so the system
-- messages, alt status and shot check-offs come out exactly as in the app.
-- Image files are not included; the app shows a placeholder when a file is missing.
-- ---------------------------------------------------------------------------
create or replace function pg_temp.send(code text, look int) returns uuid language plpgsql as $$
declare pid uuid := (select id from seed_ids where k = 'project'); f public.frames;
begin
  perform set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000003', true); -- Rafi
  f := public.send_frame(pid, (select id from public.shots where project_id = pid and number = look),
                         pid::text || '/frames/' || code || '.jpg', pid::text || '/frames/' || code || '_preview.jpg', code);
  return f.id;
end $$;

create or replace function pg_temp.approve(code text, who uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', who::text, true);
  perform public.approve_frame((select id from public.frames where frame_code = code));
end $$;

select pg_temp.send('HLD_0138', 1);
select pg_temp.send('HLD_0141', 1);
select pg_temp.approve('HLD_0141', '10000000-0000-4000-8000-000000000009');  -- Carla
select pg_temp.send('HLD_0144', 2);
select pg_temp.send('HLD_0146', 2);
select pg_temp.approve('HLD_0146', '10000000-0000-4000-8000-000000000010');  -- Erin
select pg_temp.send('HLD_0149', 3);
select pg_temp.send('HLD_0152', 3);
select pg_temp.approve('HLD_0152', '10000000-0000-4000-8000-000000000009');  -- Carla
select pg_temp.send('HLD_0158', 4);
select pg_temp.send('HLD_0160', 4);
select pg_temp.send('HLD_0163', 4);

update public.frames set is_favorite = true where frame_code in ('HLD_0141', 'HLD_0152');

insert into public.frame_comments (project_id, frame_id, author_id, body)
select f.project_id, f.id, c.author, c.body
from (values ('HLD_0141', '10000000-0000-4000-8000-000000000009'::uuid, 'This one. Cap highlight is perfect.'),
             ('HLD_0160', '10000000-0000-4000-8000-000000000010'::uuid, 'Can we see one with her chin slightly down?')) c(code, author, body)
join public.frames f on f.frame_code = c.code;

-- Put the frame activity on this morning's timeline, like the prototype.
update public.frames f set sent_at = pg_temp.at(x.sent),
       approved_at = case when f.status = 'approved' then pg_temp.at(x.appr) end
from (values ('HLD_0138', '09:58', null), ('HLD_0141', '10:14', '10:21'), ('HLD_0144', '10:40', null),
             ('HLD_0146', '10:52', '11:04'), ('HLD_0149', '11:22', null), ('HLD_0152', '11:30', '11:38'),
             ('HLD_0158', '11:50', null), ('HLD_0160', '11:50', null), ('HLD_0163', '11:51', null)) x(code, sent, appr)
where f.frame_code = x.code;

update public.messages m set created_at = case when m.body like '%approved%' then f.approved_at else f.sent_at end
from public.frames f where m.frame_id = f.id and m.is_system;

update public.shots s set done_at = f.approved_at from public.frames f where s.approved_frame_id = f.id;

-- ---------------------------------------------------------------------------
-- Walkie log
-- ---------------------------------------------------------------------------
insert into public.ptt_transmissions (project_id, ptt_channel_id, speaker_id, started_at, duration_ms)
select pc.project_id, pc.id, p.id, pg_temp.at(x.t), x.ms
from (values ('All crew', 'jonah', '11:39', 2100), ('All crew', 'maya', '11:41', 5800),
             ('G&E', 'dee', '11:44', 3200), ('Glam', 'lena', '11:20', 4400)) x(ch, who, t, ms)
join public.ptt_channels pc on pc.name = x.ch and pc.project_id = (select id from seed_ids where k = 'project')
join seed_people p on p.email = x.who || '@halden.example';

select set_config('request.jwt.claim.sub', '', false);
drop table seed_ids;
drop table seed_people;
