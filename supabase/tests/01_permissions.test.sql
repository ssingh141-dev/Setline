-- Who can see and do what. Mirrors the role table in the brief.
begin;
select plan(34);

create temp table t_ctx as select tests.setup() as pid;
grant select on t_ctx to authenticated;

-- ---------------------------------------------------------------------------
-- Channels each role can see
-- ---------------------------------------------------------------------------
create or replace function pg_temp.chans(r text) returns text language plpgsql as $$
declare out text;
begin
  perform tests.act_as(r);
  select string_agg(slug, ',' order by sort_order) into out from public.channels;
  perform tests.as_admin();
  return out;
end $$;

select is(pg_temp.chans('producer'),     'general,crew,glam,wardrobe,digi-tech,client-review,talent', 'producer sees every channel');
select is(pg_temp.chans('photographer'), 'general,crew,glam,wardrobe,digi-tech,client-review,talent', 'photographer sees every channel');
select is(pg_temp.chans('digi_tech'),    'general,crew,digi-tech,client-review', 'digi tech sees general, crew, digi, client');
select is(pg_temp.chans('crew'),         'general,crew,digi-tech', 'crew sees general, crew, digi');
select is(pg_temp.chans('glam'),         'general,glam,wardrobe', 'glam sees general, glam, wardrobe');
select is(pg_temp.chans('agency'),       'general,client-review', 'agency sees general, client');
select is(pg_temp.chans('client'),       'general,client-review', 'client sees general, client');
select is(pg_temp.chans('talent'),       'general,talent', 'talent sees general, talent');
select is(pg_temp.chans('outsider'),     null, 'someone not on the project sees nothing');

-- ---------------------------------------------------------------------------
-- Messages follow channel visibility
-- ---------------------------------------------------------------------------
select tests.act_as('crew');
insert into public.messages (project_id, channel_id, sender_id, body)
select project_id, id, tests.u('crew'), 'Heads on stands 1 to 3' from public.channels where slug = 'crew';
select tests.act_as('client');
select is((select count(*) from public.messages m join public.channels c on c.id = m.channel_id where c.slug = 'crew'), 0::bigint,
  'client cannot read crew messages');
select throws_ok(
  format($$insert into public.messages (project_id, channel_id, sender_id, body) values (%L, (select id from public.channels where project_id = %L and slug = 'crew'), %L, 'hi')$$,
         (select pid from t_ctx), (select pid from t_ctx), tests.u('client')),
  '42501', null, 'client cannot post in crew (channel id known)');
select throws_ok(
  format($$insert into public.messages (project_id, channel_id, sender_id, body) select project_id, id, %L, 'as Maya' from public.channels where slug = 'general'$$, tests.u('producer')),
  '42501', null, 'nobody can post as someone else');
select throws_ok(
  $$insert into public.messages (project_id, channel_id, sender_id, body, is_system) select project_id, id, auth.uid(), 'fake approval', true from public.channels where slug = 'client-review'$$,
  '42501', null, 'nobody can post a fake system message');
select lives_ok(
  $$insert into public.messages (project_id, channel_id, sender_id, body) select project_id, id, auth.uid(), 'Looks great' from public.channels where slug = 'client-review'$$,
  'client can post in client-review');
select tests.as_admin();

-- ---------------------------------------------------------------------------
-- Walkie
-- ---------------------------------------------------------------------------
create or replace function pg_temp.ptt(r text) returns bigint language plpgsql as $$
declare n bigint;
begin
  perform tests.act_as(r); select count(*) into n from public.ptt_channels; perform tests.as_admin(); return n;
end $$;
select is(pg_temp.ptt('crew'),   1::bigint, 'crew gets the walkie');
select is(pg_temp.ptt('glam'),   1::bigint, 'glam gets the walkie');
select is(pg_temp.ptt('client'), 0::bigint, 'client never sees a walkie channel');
select is(pg_temp.ptt('agency'), 0::bigint, 'agency never sees a walkie channel');
select is(pg_temp.ptt('talent'), 0::bigint, 'talent never sees a walkie channel');

select tests.act_as('client');
select throws_ok(
  format($$insert into public.ptt_transmissions (project_id, ptt_channel_id, speaker_id, started_at, duration_ms) select %L, (select id from public.ptt_channels where project_id = %L limit 1), auth.uid(), now(), 1000$$,
         (select pid from t_ctx), (select pid from t_ctx)),
  null, null, 'client cannot log a transmission');
select tests.as_admin();

-- ---------------------------------------------------------------------------
-- Frames
-- ---------------------------------------------------------------------------
create or replace function pg_temp.frames(r text) returns bigint language plpgsql as $$
declare n bigint;
begin
  perform tests.act_as(r); select count(*) into n from public.frames; perform tests.as_admin(); return n;
end $$;
select is(pg_temp.frames('client'), 3::bigint, 'client sees frames');
select is(pg_temp.frames('digi_tech'), 3::bigint, 'digi tech sees frames');
select is(pg_temp.frames('crew'), 0::bigint, 'crew does not see frames');
select is(pg_temp.frames('talent'), 0::bigint, 'talent does not see frames');

select tests.act_as('client');
select throws_ok($$update public.frames set status = 'approved'$$, '42501', null, 'client cannot set status directly');
select lives_ok($$update public.frames set is_favorite = true where frame_code = 'TST_0001'$$, 'client can favorite');
select throws_ok(
  format($$select public.send_frame(%L, null, %L, null, 'TST_9999')$$, (select pid from t_ctx), (select pid from t_ctx) || '/frames/x.jpg'),
  '42501', null, 'client cannot send frames');
select tests.act_as('digi_tech');
select throws_ok(
  $$select public.approve_frame((select id from public.frames where frame_code = 'TST_0001'))$$,
  '42501', null, 'digi tech cannot approve');
select throws_ok($$insert into public.frame_comments (project_id, frame_id, author_id, body) select project_id, id, auth.uid(), 'hi' from public.frames limit 1$$,
  '42501', null, 'digi tech cannot comment on frames');
select tests.as_admin();

-- ---------------------------------------------------------------------------
-- Shot list and management
-- ---------------------------------------------------------------------------
select tests.act_as('crew');
select lives_ok($$update public.shots set is_done = true where number = 5$$, 'crew can check off a look');
select tests.act_as('glam');
select is((select count(*) from public.shots), 2::bigint, 'glam can read the shot list');
select results_eq($$update public.shots set name = 'x' returning 1$$, array[]::int[], 'glam cannot edit the shot list');
select tests.act_as('talent');
select is((select count(*) from public.shots), 0::bigint, 'talent does not see the shot list');
select tests.act_as('photographer');
select throws_ok(format($$select public.create_invite(%L, 'crew')$$, (select pid from t_ctx)), '42501', null, 'only the producer can invite');
select tests.as_admin();

select * from finish();
rollback;
