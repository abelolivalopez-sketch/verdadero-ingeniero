-- =====================================================================
--  VERDADERO INGENIERO · Esquema de base de datos (Supabase / PostgreSQL)
--  Ejecutar UNA vez en: Supabase → SQL Editor → New query → Run
--  Es idempotente: se puede volver a ejecutar sin perder datos.
-- =====================================================================

create schema if not exists private;

-- ---------------------------------------------------------------------
-- 1. CATÁLOGO DEL PROGRAMA (lectura para usuarios autenticados)
-- ---------------------------------------------------------------------
create table if not exists public.phases (
  id          smallint primary key,
  title       text not null,
  description text
);

create table if not exists public.modules (
  id          text primary key,                       -- 'M01'
  phase_id    smallint not null references public.phases(id),
  position    smallint not null,
  title       text not null,
  description text,
  day_start   int not null,
  day_end     int not null,
  color       text not null default '#4FD1FF',
  tools       text[] not null default '{}',
  constraint modules_range_chk check (day_end >= day_start)
);

create table if not exists public.daily_content (
  day_number        int primary key check (day_number >= 1),
  module_id         text not null references public.modules(id),
  title             text not null,
  objective         text,
  body_md           text,                              -- teoría (Markdown + LaTeX)
  practice_md       text,                              -- práctica guiada
  estimated_minutes smallint not null default 60,
  is_ready          boolean generated always as (body_md is not null) stored,
  updated_at        timestamptz not null default now()
);
create index if not exists daily_content_module_idx on public.daily_content(module_id);

create table if not exists public.questions (
  id               uuid primary key default gen_random_uuid(),
  external_key     text unique,                        -- 'D001-Q01' (seeds idempotentes)
  day_number       int not null references public.daily_content(day_number) on delete cascade,
  difficulty_level smallint not null check (difficulty_level between 1 and 3),
  qtype            text not null default 'mcq' check (qtype in ('mcq','numeric')),
  prompt_md        text not null,
  options          jsonb,                              -- ["opción A", "opción B", ...]
  correct_index    smallint,                           -- índice correcto (mcq)
  answer_value     double precision,                   -- valor correcto (numeric)
  tolerance_pct    real not null default 2,            -- tolerancia relativa (%)
  unit             text,
  explanation_md   text not null,
  tags             text[] not null default '{}',
  created_at       timestamptz not null default now(),
  constraint questions_mcq_chk check (
    qtype <> 'mcq' or (
      jsonb_typeof(options) = 'array'
      and jsonb_array_length(options) between 2 and 6
      and correct_index >= 0 and correct_index < jsonb_array_length(options))),
  constraint questions_num_chk check (qtype <> 'numeric' or answer_value is not null)
);
create index if not exists questions_day_level_idx on public.questions(day_number, difficulty_level);

-- ---------------------------------------------------------------------
-- 2. DATOS DEL USUARIO
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  display_name   text,
  current_day    int not null default 1 check (current_day >= 1),  -- > total de días = programa terminado
  current_level  smallint not null default 1 check (current_level between 1 and 3), -- dificultad adaptativa
  xp             int not null default 0,
  streak         int not null default 0,
  best_streak    int not null default 0,
  last_pass_date date,
  timezone       text not null default 'Europe/Madrid',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create table if not exists public.exam_history (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles(id) on delete cascade,
  day_number       int not null references public.daily_content(day_number),
  difficulty_level smallint not null,
  mode             text not null default 'daily' check (mode in ('daily','practice')),
  question_ids     uuid[] not null,                    -- preguntas del día servidas
  review_ids       uuid[] not null default '{}',       -- preguntas de repaso (días anteriores)
  total_count      int not null,
  correct_count    int,
  score            numeric(5,2),                       -- % de aciertos
  passed           boolean,
  xp_earned        int not null default 0,
  level_change     smallint not null default 0,        -- -1, 0, +1
  started_at       timestamptz not null default now(),
  completed_at     timestamptz
);
create index if not exists exam_history_user_idx on public.exam_history(user_id, started_at desc);

create table if not exists public.exam_answers (
  exam_id     uuid not null references public.exam_history(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  answer      jsonb,
  is_correct  boolean not null,
  is_review   boolean not null default false,
  answered_at timestamptz not null default now(),
  primary key (exam_id, question_id)
);
create index if not exists exam_answers_user_q_idx on public.exam_answers(user_id, question_id);

-- Repaso espaciado (sistema Leitner: cajas 1..5 → 1, 2, 4, 8, 16 días)
create table if not exists public.review_queue (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  box         smallint not null default 1 check (box between 1 and 5),
  due_on      date not null,
  updated_at  timestamptz not null default now(),
  primary key (user_id, question_id)
);
create index if not exists review_queue_due_idx on public.review_queue(user_id, due_on);

-- ---------------------------------------------------------------------
-- 3. SEGURIDAD (RLS)
-- ---------------------------------------------------------------------
alter table public.phases        enable row level security;
alter table public.modules       enable row level security;
alter table public.daily_content enable row level security;
alter table public.questions     enable row level security;   -- sin políticas: solo vía funciones
alter table public.profiles      enable row level security;
alter table public.exam_history  enable row level security;
alter table public.exam_answers  enable row level security;
alter table public.review_queue  enable row level security;

drop policy if exists "catalogo legible" on public.phases;
create policy "catalogo legible" on public.phases for select to authenticated using (true);
drop policy if exists "catalogo legible" on public.modules;
create policy "catalogo legible" on public.modules for select to authenticated using (true);
drop policy if exists "catalogo legible" on public.daily_content;
create policy "catalogo legible" on public.daily_content for select to authenticated using (true);

drop policy if exists "perfil propio lectura" on public.profiles;
create policy "perfil propio lectura" on public.profiles for select to authenticated
  using (id = (select auth.uid()));
drop policy if exists "perfil propio edicion" on public.profiles;
create policy "perfil propio edicion" on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "historial propio" on public.exam_history;
create policy "historial propio" on public.exam_history for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists "respuestas propias" on public.exam_answers;
create policy "respuestas propias" on public.exam_answers for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists "repaso propio" on public.review_queue;
create policy "repaso propio" on public.review_queue for select to authenticated
  using (user_id = (select auth.uid()));

-- El progreso (día, nivel, XP, racha) solo lo cambia el servidor al corregir.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (display_name, timezone) on public.profiles to authenticated;
revoke insert, update, delete on public.exam_history, public.exam_answers, public.review_queue
  from anon, authenticated;
revoke all on public.questions from anon, authenticated;
revoke insert, update, delete on public.phases, public.modules, public.daily_content
  from anon, authenticated;

-- ---------------------------------------------------------------------
-- 4. PERFIL AUTOMÁTICO AL REGISTRARSE
-- ---------------------------------------------------------------------
create or replace function private.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users for each row execute function private.handle_new_user();

-- ---------------------------------------------------------------------
-- 5. FUNCIONES AUXILIARES (esquema privado, no expuesto por la API)
-- ---------------------------------------------------------------------
create or replace function private.total_days()
returns int language sql stable set search_path = '' as $$
  select coalesce(max(day_number), 0) from public.daily_content;
$$;

create or replace function private.today_for(p_tz text)
returns date language sql stable set search_path = '' as $$
  select (now() at time zone coalesce(p_tz, 'Europe/Madrid'))::date;
$$;

-- Devuelve el examen SIN las soluciones.
create or replace function private.exam_payload(p_exam_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'exam_id',          e.id,
    'day_number',       e.day_number,
    'difficulty_level', e.difficulty_level,
    'mode',             e.mode,
    'started_at',       e.started_at,
    'total',            e.total_count,
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id',               q.id,
               'qtype',            q.qtype,
               'prompt_md',        q.prompt_md,
               'options',          q.options,
               'unit',             q.unit,
               'difficulty_level', q.difficulty_level,
               'is_review',        x.is_review,
               'source_day',       q.day_number)
             order by x.is_review, q.difficulty_level, x.ord)
      from (
        select t.qid, t.ord, false as is_review from unnest(e.question_ids) with ordinality as t(qid, ord)
        union all
        select t.qid, t.ord, true  as is_review from unnest(e.review_ids)  with ordinality as t(qid, ord)
      ) x
      join public.questions q on q.id = x.qid), '[]'::jsonb))
  from public.exam_history e
  where e.id = p_exam_id;
$$;

-- ---------------------------------------------------------------------
-- 5b. CARGA DE CONTENIDO (la usan los scripts de seed; no accesible desde la app)
-- ---------------------------------------------------------------------
-- Catálogo: {"phases":[{id,title,description}], "modules":[{id,phase,position,title,description,
--            day_start,day_end,color,tools}], "days":[{d,m,t,o}]}
create or replace function private.upsert_catalog(p jsonb)
returns void language plpgsql set search_path = '' as $$
begin
  insert into public.phases (id, title, description)
  select (x->>'id')::smallint, x->>'title', x->>'description'
    from jsonb_array_elements(p->'phases') as x
  on conflict (id) do update set title = excluded.title, description = excluded.description;

  insert into public.modules (id, phase_id, position, title, description, day_start, day_end, color, tools)
  select x->>'id', (x->>'phase')::smallint, (x->>'position')::smallint, x->>'title', x->>'description',
         (x->>'day_start')::int, (x->>'day_end')::int, coalesce(x->>'color', '#4FD1FF'),
         coalesce(array(select jsonb_array_elements_text(x->'tools')), '{}')
    from jsonb_array_elements(p->'modules') as x
  on conflict (id) do update set phase_id = excluded.phase_id, position = excluded.position,
     title = excluded.title, description = excluded.description, day_start = excluded.day_start,
     day_end = excluded.day_end, color = excluded.color, tools = excluded.tools;

  insert into public.daily_content (day_number, module_id, title, objective)
  select (x->>'d')::int, x->>'m', x->>'t', x->>'o'
    from jsonb_array_elements(p->'days') as x
  on conflict (day_number) do update set module_id = excluded.module_id,
     title = excluded.title, objective = excluded.objective;
end $$;

-- Un día completo: {"day":1,"minutes":60,"body":"...","practice":"...",
--   "questions":[{k,d,t,p,o,c,v,tol,u,e}]}   (k=external_key, t=qtype, p=prompt, o=options,
--   c=correct_index, v=answer_value, u=unit, e=explanation)
create or replace function private.upsert_day(p jsonb)
returns void language plpgsql set search_path = '' as $$
declare
  v_day int := (p->>'day')::int;
begin
  update public.daily_content
     set body_md = p->>'body', practice_md = p->>'practice',
         estimated_minutes = coalesce((p->>'minutes')::smallint, 60), updated_at = now()
   where day_number = v_day;
  if not found then raise exception 'El día % no existe en el catálogo', v_day; end if;

  delete from public.questions q
   where q.day_number = v_day
     and q.external_key not in (select x->>'k' from jsonb_array_elements(p->'questions') as x);

  insert into public.questions (external_key, day_number, difficulty_level, qtype, prompt_md, options,
                                correct_index, answer_value, tolerance_pct, unit, explanation_md)
  select x->>'k', v_day, (x->>'d')::smallint, x->>'t', x->>'p',
         case when x ? 'o' then x->'o' end, (x->>'c')::smallint, (x->>'v')::double precision,
         coalesce((x->>'tol')::real, 2), x->>'u', x->>'e'
    from jsonb_array_elements(p->'questions') as x
  on conflict (external_key) do update set day_number = excluded.day_number,
     difficulty_level = excluded.difficulty_level, qtype = excluded.qtype, prompt_md = excluded.prompt_md,
     options = excluded.options, correct_index = excluded.correct_index, answer_value = excluded.answer_value,
     tolerance_pct = excluded.tolerance_pct, unit = excluded.unit, explanation_md = excluded.explanation_md;
end $$;

-- ---------------------------------------------------------------------
-- 6. API PARA LA APP (RPC)
-- ---------------------------------------------------------------------

-- 6.1 Panel de inicio: perfil + estado de hoy + lección del día
create or replace function public.get_dashboard()
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid   uuid := auth.uid();
  v_p     public.profiles;
  v_today date;
  v_day   int;
  v_total int;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;
  select * into v_p from public.profiles where id = v_uid;
  v_today := private.today_for(v_p.timezone);
  v_total := private.total_days();
  v_day   := least(v_p.current_day, v_total);

  return jsonb_build_object(
    'profile', to_jsonb(v_p),
    'today', v_today,
    'effective_streak', case when v_p.last_pass_date >= v_today - 1 then v_p.streak else 0 end,
    'passed_today', coalesce(v_p.last_pass_date = v_today, false),
    'program_completed', v_p.current_day > v_total,
    'total_days', v_total,
    'exams_today', (select count(*) from public.exam_history h
                     where h.user_id = v_uid and h.completed_at is not null
                       and (h.completed_at at time zone v_p.timezone)::date = v_today),
    'reviews_due', (select count(*) from public.review_queue r
                     where r.user_id = v_uid and r.due_on <= v_today),
    'lesson', (select jsonb_build_object(
                  'day_number', c.day_number, 'title', c.title, 'objective', c.objective,
                  'is_ready', c.is_ready, 'estimated_minutes', c.estimated_minutes,
                  'module_id', m.id, 'module_title', m.title, 'module_color', m.color,
                  'phase_id', m.phase_id,
                  'question_count', (select count(*) from public.questions q where q.day_number = c.day_number))
                from public.daily_content c join public.modules m on m.id = c.module_id
                where c.day_number = v_day)
  );
end $$;

-- 6.2 Empezar (o reanudar) el examen del día.
--     p_day = null → examen diario del día actual.
--     p_day < día actual → examen de práctica (no cambia el progreso, XP a la mitad).
create or replace function public.start_daily_exam(p_day int default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid     uuid := auth.uid();
  v_p       public.profiles;
  v_today   date;
  v_day     int;
  v_mode    text;
  v_exam_id uuid;
  v_ids     uuid[] := '{}';
  v_review  uuid[] := '{}';
  v_target  int[];
  v_need    int;
  d         int;
  c_day_questions constant int := 10;   -- preguntas del día por examen
  c_max_review    constant int := 3;    -- preguntas de repaso añadidas
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;
  insert into public.profiles (id) values (v_uid) on conflict (id) do nothing;
  select * into v_p from public.profiles where id = v_uid for update;
  v_today := private.today_for(v_p.timezone);

  v_day := coalesce(p_day, v_p.current_day);
  if v_day > private.total_days() then raise exception 'program_completed'; end if;
  if v_day < 1 or v_day > v_p.current_day then raise exception 'day_locked'; end if;
  v_mode := case when v_day = v_p.current_day then 'daily' else 'practice' end;

  if not exists (select 1 from public.questions where day_number = v_day) then
    raise exception 'content_pending';
  end if;

  -- Reanudar un examen a medias (mismo día y modo, < 6 h) para no "pescar" preguntas fáciles.
  select h.id into v_exam_id from public.exam_history h
   where h.user_id = v_uid and h.day_number = v_day and h.mode = v_mode
     and h.completed_at is null and h.started_at > now() - interval '6 hours'
   order by h.started_at desc limit 1;
  if v_exam_id is not null then
    return private.exam_payload(v_exam_id);
  end if;
  delete from public.exam_history where user_id = v_uid and completed_at is null;

  -- Reparto por dificultad según el nivel del usuario: [básico, intermedio, avanzado]
  v_target := case v_p.current_level
                when 1 then array[5,3,2]
                when 2 then array[2,5,3]
                else        array[1,4,5] end;

  for d in 1..3 loop
    v_ids := v_ids || coalesce(array(
      select q.id from public.questions q
       where q.day_number = v_day and q.difficulty_level = d
       order by exists (select 1 from public.exam_answers a
                         where a.user_id = v_uid and a.question_id = q.id and a.is_correct),
                random()
       limit v_target[d]), '{}');
  end loop;

  -- Si faltan preguntas de algún nivel, completar con las más cercanas al nivel del usuario.
  v_need := c_day_questions - coalesce(array_length(v_ids, 1), 0);
  if v_need > 0 then
    v_ids := v_ids || coalesce(array(
      select q.id from public.questions q
       where q.day_number = v_day and not (q.id = any(v_ids))
       order by abs(q.difficulty_level - v_p.current_level), random()
       limit v_need), '{}');
  end if;

  -- Repaso espaciado: preguntas falladas de días anteriores que tocan hoy.
  if v_mode = 'daily' then
    v_review := coalesce(array(
      select r.question_id from public.review_queue r
        join public.questions q on q.id = r.question_id
       where r.user_id = v_uid and r.due_on <= v_today and q.day_number <> v_day
       order by r.due_on, r.box, random()
       limit c_max_review), '{}');
  end if;

  insert into public.exam_history (user_id, day_number, difficulty_level, mode,
                                   question_ids, review_ids, total_count)
  values (v_uid, v_day, v_p.current_level, v_mode, v_ids, v_review,
          coalesce(array_length(v_ids, 1), 0) + coalesce(array_length(v_review, 1), 0))
  returning id into v_exam_id;

  return private.exam_payload(v_exam_id);
end $$;

-- 6.3 Entregar el examen: corrige en el servidor y aplica el algoritmo de niveles.
--     p_answers = [{"question_id": "...", "choice": 2}, {"question_id": "...", "value": 245.3}]
create or replace function public.submit_exam(p_exam_id uuid, p_answers jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid          uuid := auth.uid();
  v_exam         public.exam_history;
  v_p            public.profiles;
  v_today        date;
  v_correct      int := 0;
  v_total        int := 0;
  v_score        numeric(5,2);
  v_passed       boolean;
  v_xp           int := 0;
  v_level_change smallint := 0;
  v_advanced     boolean := false;
  v_streak       int;
  v_ans          jsonb;
  v_ok           boolean;
  v_val          double precision;
  v_results      jsonb := '[]'::jsonb;
  r              record;
begin
  if v_uid is null then raise exception 'not_authenticated'; end if;

  select * into v_exam from public.exam_history
   where id = p_exam_id and user_id = v_uid for update;
  if not found then raise exception 'exam_not_found'; end if;
  if v_exam.completed_at is not null then raise exception 'exam_already_submitted'; end if;

  select * into v_p from public.profiles where id = v_uid for update;
  v_today := private.today_for(v_p.timezone);

  for r in
    select q.id, q.qtype, q.prompt_md, q.options, q.correct_index, q.answer_value,
           q.tolerance_pct, q.unit, q.explanation_md, q.difficulty_level, q.day_number,
           x.is_review
      from (
        select t.qid, t.ord, false as is_review from unnest(v_exam.question_ids) with ordinality as t(qid, ord)
        union all
        select t.qid, t.ord, true  as is_review from unnest(v_exam.review_ids)  with ordinality as t(qid, ord)
      ) x
      join public.questions q on q.id = x.qid
     order by x.is_review, q.difficulty_level, x.ord
  loop
    v_total := v_total + 1;
    v_ans := null;
    select e.value into v_ans
      from jsonb_array_elements(coalesce(p_answers, '[]'::jsonb)) as e(value)
     where e.value->>'question_id' = r.id::text
     limit 1;

    v_ok := false;
    if v_ans is not null then
      if r.qtype = 'mcq' and jsonb_typeof(v_ans->'choice') = 'number' then
        v_ok := (v_ans->>'choice')::numeric = r.correct_index;
      elsif r.qtype = 'numeric' and jsonb_typeof(v_ans->'value') = 'number' then
        v_val := (v_ans->>'value')::double precision;
        v_ok  := abs(v_val - r.answer_value)
                 <= greatest(abs(r.answer_value) * r.tolerance_pct / 100.0, 1e-9);
      end if;
    end if;

    if v_ok then
      v_correct := v_correct + 1;
      v_xp := v_xp + 10 * r.difficulty_level;
    end if;

    insert into public.exam_answers (exam_id, question_id, user_id, answer, is_correct, is_review)
    values (v_exam.id, r.id, v_uid, v_ans, v_ok, r.is_review)
    on conflict (exam_id, question_id) do nothing;

    -- Repaso espaciado (Leitner)
    if not v_ok then
      insert into public.review_queue (user_id, question_id, box, due_on)
      values (v_uid, r.id, 1, v_today + 1)
      on conflict (user_id, question_id)
      do update set box = 1, due_on = v_today + 1, updated_at = now();
    else
      delete from public.review_queue
       where user_id = v_uid and question_id = r.id and box >= 5;
      update public.review_queue
         set box = box + 1,
             due_on = v_today + (array[1, 2, 4, 8, 16])[box + 1],
             updated_at = now()
       where user_id = v_uid and question_id = r.id;
    end if;

    v_results := v_results || jsonb_build_object(
      'question_id',      r.id,
      'qtype',            r.qtype,
      'prompt_md',        r.prompt_md,
      'options',          r.options,
      'correct_index',    r.correct_index,
      'answer_value',     r.answer_value,
      'tolerance_pct',    r.tolerance_pct,
      'unit',             r.unit,
      'explanation_md',   r.explanation_md,
      'difficulty_level', r.difficulty_level,
      'source_day',       r.day_number,
      'is_review',        r.is_review,
      'your_answer',      v_ans,
      'is_correct',       v_ok);
  end loop;

  v_score  := round(100.0 * v_correct / greatest(v_total, 1), 2);
  v_passed := v_score >= 80;
  if v_passed then v_xp := v_xp + 50; end if;
  if v_exam.mode = 'practice' then v_xp := v_xp / 2; end if;

  -- ALGORITMO DE PROGRESIÓN (solo examen diario del día actual)
  --   ≥ 80 %  → aprobado: avanza al día siguiente y suma racha
  --   ≥ 90 %  → además sube la dificultad (máx. 3)
  --   < 50 %  → baja la dificultad (mín. 1); se repite el día con preguntas nuevas
  --   fallos  → entran en la cola de repaso espaciado
  if v_exam.mode = 'daily' and v_exam.day_number = v_p.current_day then
    if v_passed then
      v_advanced := true;
      if v_score >= 90 and v_p.current_level < 3 then v_level_change := 1; end if;
      v_streak := case
                    when v_p.last_pass_date = v_today     then v_p.streak
                    when v_p.last_pass_date = v_today - 1 then v_p.streak + 1
                    else 1 end;
      update public.profiles
         set current_day    = least(current_day + 1, private.total_days() + 1),
             current_level  = current_level + v_level_change,
             streak         = v_streak,
             best_streak    = greatest(best_streak, v_streak),
             last_pass_date = v_today
       where id = v_uid;
    elsif v_score < 50 and v_p.current_level > 1 then
      v_level_change := -1;
      update public.profiles set current_level = current_level - 1 where id = v_uid;
    end if;
  end if;

  update public.profiles set xp = xp + v_xp, updated_at = now() where id = v_uid;

  update public.exam_history
     set correct_count = v_correct, total_count = v_total, score = v_score, passed = v_passed,
         xp_earned = v_xp, level_change = v_level_change, completed_at = now()
   where id = v_exam.id;

  select * into v_p from public.profiles where id = v_uid;

  return jsonb_build_object(
    'exam_id',      v_exam.id,
    'mode',         v_exam.mode,
    'day_number',   v_exam.day_number,
    'score',        v_score,
    'passed',       v_passed,
    'correct',      v_correct,
    'total',        v_total,
    'xp_earned',    v_xp,
    'level_change', v_level_change,
    'day_advanced', v_advanced,
    'profile',      to_jsonb(v_p),
    'results',      v_results);
end $$;

-- 6.4 Estadísticas por módulo para la pantalla de progreso
create or replace function public.get_module_stats()
returns table (module_id text, exams int, passed int, avg_score numeric, best_score numeric)
language sql stable security definer set search_path = '' as $$
  select c.module_id,
         count(*)::int,
         count(*) filter (where h.passed)::int,
         round(avg(h.score), 1),
         max(h.score)
    from public.exam_history h
    join public.daily_content c on c.day_number = h.day_number
   where h.user_id = auth.uid() and h.completed_at is not null
   group by c.module_id
   order by c.module_id;
$$;

-- Permisos de ejecución: solo usuarios autenticados.
revoke all on function public.get_dashboard()               from public, anon;
revoke all on function public.start_daily_exam(int)         from public, anon;
revoke all on function public.submit_exam(uuid, jsonb)      from public, anon;
revoke all on function public.get_module_stats()            from public, anon;
grant execute on function public.get_dashboard()            to authenticated;
grant execute on function public.start_daily_exam(int)      to authenticated;
grant execute on function public.submit_exam(uuid, jsonb)   to authenticated;
grant execute on function public.get_module_stats()         to authenticated;

revoke all on all functions in schema private from public, anon, authenticated;
