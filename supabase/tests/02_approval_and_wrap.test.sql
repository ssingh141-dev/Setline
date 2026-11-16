-- The approval transaction and the wrapped (read only) rules.
begin;
select plan(17);

create temp table t_ctx as select tests.setup() as pid;
grant select on t_ctx to authenticated;

-- ---------------------------------------------------------------------------
-- Approving a frame does all four steps at once
-- ---------------------------------------------------------------------------
select tests.act_as('client');
select is((public.approve_frame((select id from public.frames where frame_code = 'TST_0002'))).status,
          'approved'::public.frame_status, 'client approves TST_0002');
select tests.as_admin();

select is((select status from public.frames where frame_code = 'TST_0002'), 'approved'::public.frame_status, '1. frame is approved');
select is((select approved_by from public.frames where frame_code = 'TST_0002'), tests.u('client'), '   approved by the client');
select is((select status from public.frames where frame_code = 'TST_0001'), 'alt'::public.frame_status, '2. other option for the same look is now Alt');
select is((select status from public.frames where frame_code = 'TST_0003'), 'pending'::public.frame_status, '   frames for other looks are untouched');
select ok((select is_done from public.shots where project_id = (select pid from t_ctx) and number = 4), '3. look 04 is checked off');
select is((select f.frame_code from public.shots s join public.frames f on f.id = s.approved_frame_id where s.project_id = (select pid from t_ctx) and s.number = 4),
          'TST_0002', '   and points at the approved frame');
select is((select m.body from public.messages m join public.channels c on c.id = m.channel_id
           where c.slug = 'client-review' and c.project_id = (select pid from t_ctx) and m.is_system and m.body like '%approved%'),
          'Client approved TST_0002. Look 04 checked off.', '4. system message posted in client-review');

select tests.act_as('agency');
select throws_ok($$select public.approve_frame((select id from public.frames where frame_code = 'TST_0001'))$$,
  null, 'Only frames waiting for approval can be approved.', 'an Alt frame cannot be approved again');
select tests.act_as('crew');
select throws_ok($$update public.shots set approved_frame_id = null$$, '42501', null, 'nobody can rewrite which frame approved a look');
select tests.as_admin();

-- ---------------------------------------------------------------------------
-- Wrap
-- ---------------------------------------------------------------------------
select tests.act_as('photographer');
select throws_ok(format($$select public.set_wrapped(%L, true)$$, (select pid from t_ctx)), '42501', null, 'photographer cannot wrap');
select tests.act_as('producer');
select lives_ok(format($$select public.set_wrapped(%L, true)$$, (select pid from t_ctx)), 'producer wraps the project');

select throws_ok($$insert into public.messages (project_id, channel_id, sender_id, body) select project_id, id, auth.uid(), 'after wrap' from public.channels where slug = 'general'$$,
  'P0001', 'This project is wrapped and read only.', 'no posting after wrap');
select throws_ok($$update public.projects set name = 'Renamed'$$, 'P0001', null, 'no editing project details after wrap');
select tests.act_as('client');
select throws_ok($$select public.approve_frame((select id from public.frames where frame_code = 'TST_0003'))$$,
  'P0001', null, 'no approvals after wrap');
select is((select count(*) from public.messages), 4::bigint, 'client can still read the archive (3 sent + 1 approved)');

select tests.act_as('producer');
select lives_ok(format($$select public.set_wrapped(%L, false)$$, (select pid from t_ctx)), 'producer can reopen');
select tests.as_admin();

select * from finish();
rollback;
