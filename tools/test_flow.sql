-- Prueba de extremo a extremo del algoritmo de exámenes (Postgres local con test_stub_supabase.sql)
\set ON_ERROR_STOP 1
\pset pager off
insert into auth.users(id, email) values ('11111111-1111-1111-1111-111111111111', 'abel@test.com');
select id, display_name, current_day, current_level from public.profiles;

-- Función auxiliar de test (como superusuario): respuestas para un examen.
-- p_mode: 'ok' = todas bien, 'ko' = todas mal, 'half' = la mitad bien
create schema test;
create function test.answers(p jsonb, p_mode text) returns jsonb language sql security definer as $$
  select jsonb_agg(
    case
      when (p_mode = 'ok' or (p_mode = 'half' and e.ord % 2 = 0)) then
        case when q.qtype = 'mcq' then jsonb_build_object('question_id', q.id, 'choice', q.correct_index)
             else jsonb_build_object('question_id', q.id, 'value', q.answer_value * 1.005) end
      else
        case when q.qtype = 'mcq' then jsonb_build_object('question_id', q.id, 'choice', (q.correct_index + 1) % jsonb_array_length(q.options))
             else jsonb_build_object('question_id', q.id, 'value', q.answer_value * 1.5 + 1) end
    end)
  from jsonb_array_elements(p->'questions') with ordinality as e(v, ord)
  join public.questions q on q.id = (e.v->>'id')::uuid;
$$;
grant usage on schema test to authenticated;

-- ===== Como usuario autenticado =====
set role authenticated;
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', false);

\echo '--- dashboard inicial'
select get_dashboard() - 'profile' as dash;

\echo '--- seguridad'
do $$ begin
  perform * from public.questions;
  raise exception 'FALLO: se pudieron leer las preguntas';
exception when insufficient_privilege then raise notice 'OK: questions no legible por el cliente';
end $$;
do $$ begin
  update public.profiles set current_day = 50;
  raise exception 'FALLO: se pudo cambiar current_day';
exception when insufficient_privilege then raise notice 'OK: el progreso no se puede manipular';
end $$;
update public.profiles set display_name = 'Abel';
do $$ begin
  perform public.start_daily_exam(5);
  raise exception 'FALLO: día bloqueado accesible';
exception when others then
  if sqlerrm = 'day_locked' then raise notice 'OK: día futuro bloqueado'; else raise; end if;
end $$;

\echo '--- día 1: examen, reanudación y aprobado con 100 %'
create temp table e1 as select start_daily_exam() as p;
select p->>'mode' mode, p->>'day_number' dia, p->>'difficulty_level' nivel, jsonb_array_length(p->'questions') n,
       (select string_agg(x->>'difficulty_level', '' ) from jsonb_array_elements(p->'questions') x) reparto,
       position('correct_index' in p::text) = 0 as sin_soluciones
  from e1;
select (start_daily_exam()->>'exam_id') = (select p->>'exam_id' from e1) as reanuda_mismo_examen;
create temp table r1 as select submit_exam((select (p->>'exam_id')::uuid from e1), test.answers((select p from e1), 'ok')) as r;
select r->>'score' score, r->>'passed' passed, r->>'xp_earned' xp, r->>'level_change' lvl, r->>'day_advanced' adv,
       r->'profile'->>'current_day' dia, r->'profile'->>'current_level' nivel, r->'profile'->>'streak' racha from r1;
do $$ begin
  perform public.submit_exam((select (p->>'exam_id')::uuid from e1), '[]');
  raise exception 'FALLO: doble entrega';
exception when others then
  if sqlerrm = 'exam_already_submitted' then raise notice 'OK: no se puede entregar dos veces'; else raise; end if;
end $$;

\echo '--- día 2 (nivel 2): suspenso con 0 % → baja de nivel y repite'
create temp table e2 as select start_daily_exam() as p;
select p->>'day_number' dia, p->>'difficulty_level' nivel,
       (select string_agg(x->>'difficulty_level', '') from jsonb_array_elements(p->'questions') x) reparto from e2;
create temp table r2 as select submit_exam((select (p->>'exam_id')::uuid from e2), test.answers((select p from e2), 'ko')) as r;
select r->>'score' score, r->>'passed' passed, r->>'level_change' lvl, r->'profile'->>'current_day' dia,
       r->'profile'->>'current_level' nivel from r2;
select count(*) as en_cola_repaso, min(due_on) as primer_repaso from public.review_queue;

\echo '--- día 2 otra vez: 50 % (suspenso sin bajar de nivel 1)'
create temp table e2b as select start_daily_exam() as p;
create temp table r2b as select submit_exam((select (p->>'exam_id')::uuid from e2b), test.answers((select p from e2b), 'half')) as r;
select r->>'score' score, r->>'passed' passed, r->>'level_change' lvl, r->'profile'->>'current_level' nivel from r2b;

\echo '--- día 2 tercera vez: 100 % → aprueba'
create temp table e2c as select start_daily_exam() as p;
create temp table r2c as select submit_exam((select (p->>'exam_id')::uuid from e2c), test.answers((select p from e2c), 'ok')) as r;
select r->>'score' score, r->>'passed' passed, r->'profile'->>'current_day' dia, r->'profile'->>'current_level' nivel,
       r->'profile'->>'streak' racha, r->'profile'->>'xp' xp from r2c;

\echo '--- práctica del día 1 (no cambia progreso, XP a la mitad)'
create temp table ep as select start_daily_exam(1) as p;
create temp table rp as select submit_exam((select (p->>'exam_id')::uuid from ep), test.answers((select p from ep), 'ok')) as r;
select r->>'mode' mode, r->>'xp_earned' xp, r->'profile'->>'current_day' dia from rp;

reset role;
\echo '--- simulamos que llega el día del repaso'
update public.review_queue set due_on = current_date;
set role authenticated;

\echo '--- día 3: deben aparecer hasta 3 preguntas de repaso del día 2'
create temp table e3 as select start_daily_exam() as p;
select p->>'day_number' dia, p->>'total' total,
       (select count(*) from jsonb_array_elements(p->'questions') x where (x->>'is_review')::boolean) repasos,
       (select string_agg(distinct x->>'source_day', ',') from jsonb_array_elements(p->'questions') x where (x->>'is_review')::boolean) dias_repaso
  from e3;
create temp table r3 as select submit_exam((select (p->>'exam_id')::uuid from e3), test.answers((select p from e3), 'ok')) as r;
select r->>'score' score, r->>'passed' passed, r->'profile'->>'current_day' dia from r3;
select box, count(*) from public.review_queue group by box order by box;

\echo '--- estadísticas por módulo e historial visible'
select * from get_module_stats();
select day_number, mode, score, passed, xp_earned, level_change from public.exam_history order by started_at;

reset role;
\echo '--- contenido pendiente (día 15 sin redactar)'
update public.profiles set current_day = 15;
set role authenticated;
do $$ begin
  perform public.start_daily_exam();
  raise exception 'FALLO';
exception when others then
  if sqlerrm = 'content_pending' then raise notice 'OK: día sin contenido avisa content_pending'; else raise; end if;
end $$;
select get_dashboard()->'lesson' as leccion_15;
