-- Shared test helpers. Every test file runs inside its own transaction and rolls back.
-- Makes one user per role on a fresh project:
--   tests.u('producer') ... tests.u('talent'), project id in tests.pid().
begin;
select plan(1);

create schema if not exists tests;
grant usage on schema tests to authenticated, anon;

create or replace function tests.u(r text) returns uuid language sql immutable as $$
  select case r
    when 'producer'     then 'a0000000-0000-4000-8000-000000000001'
    when 'photographer' then 'a0000000-0000-4000-8000-000000000002'
    when 'digi_tech'    then 'a0000000-0000-4000-8000-000000000003'
    when 'crew'         then 'a0000000-0000-4000-8000-000000000004'
    when 'glam'         then 'a0000000-0000-4000-8000-000000000005'
    when 'agency'       then 'a0000000-0000-4000-8000-000000000006'
    when 'client'       then 'a0000000-0000-4000-8000-000000000007'
    when 'talent'       then 'a0000000-0000-4000-8000-000000000008'
    when 'outsider'     then 'a0000000-0000-4000-8000-000000000009'
  end::uuid
$$;

-- Become a user (as the app would, through the "authenticated" role).
create or replace function tests.act_as(r text) returns void language plpgsql as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', tests.u(r)::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', tests.u(r), 'role', 'authenticated')::text, true);
end $$;

create or replace function tests.as_admin() returns void language plpgsql as $$
begin
  perform set_config('role', 'none', true);
  perform set_config('request.jwt.claim.sub', '', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

-- Build a project with one member per role, a look and two pending frames.
create or replace function tests.setup() returns uuid language plpgsql as $$
declare pid uuid; r text; code text;
begin
  insert into auth.users (id, email, raw_user_meta_data)
  select tests.u(x), x || '@test.example', json_build_object('full_name', initcap(x) || ' Test')::jsonb
  from unnest(array['producer','photographer','digi_tech','crew','glam','agency','client','talent','outsider']) x;

  perform tests.act_as('producer');
  pid := public.create_project('Test Brand', 'Test Job');
  foreach r in array array['photographer','digi_tech','crew','glam','agency','client','talent'] loop
    perform tests.act_as('producer');
    code := public.create_invite(pid, r::public.project_role);
    perform tests.act_as(r);
    perform public.join_project(code);
  end loop;
  perform tests.as_admin();

  insert into public.shots (project_id, number, name) values (pid, 4, 'Ama holding serum'), (pid, 5, 'Texture swatch');

  perform tests.act_as('digi_tech');
  perform public.send_frame(pid, (select id from public.shots where project_id = pid and number = 4), pid || '/frames/a.jpg', null, 'TST_0001');
  perform public.send_frame(pid, (select id from public.shots where project_id = pid and number = 4), pid || '/frames/b.jpg', null, 'TST_0002');
  perform public.send_frame(pid, (select id from public.shots where project_id = pid and number = 5), pid || '/frames/c.jpg', null, 'TST_0003');
  perform tests.as_admin();
  return pid;
end $$;

grant execute on all functions in schema tests to authenticated;

select pass('helpers loaded');
select * from finish();
commit;
