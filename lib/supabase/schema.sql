-- ---------- helpers ---------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- profiles --------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  username    text not null default 'Student'
              check (char_length(btrim(username)) between 1 and 40),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
-- (email is intentionally NOT copied here; it stays in auth.users)

-- ---------- user_stats (Bucks Coins, XP, streak) ----------------------
create table if not exists public.user_stats (
  user_id             uuid primary key references auth.users (id) on delete cascade,
  bucks_coins         integer not null default 0 check (bucks_coins >= 0),
  xp                  integer not null default 0 check (xp >= 0),
  current_streak      integer not null default 0 check (current_streak >= 0),
  last_activity_date  date,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ---------- savings_goals ---------------------------------------------
create table if not exists public.savings_goals (
  user_id        uuid not null references auth.users (id) on delete cascade,
  id             text not null,                       -- client-generated id
  name           text not null check (char_length(btrim(name)) > 0),
  target_amount  numeric(14,2) not null check (target_amount > 0),
  saved_amount   numeric(14,2) not null default 0 check (saved_amount >= 0),
  deadline       timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  primary key (user_id, id)
);

-- ---------- transactions ----------------------------------------------
create table if not exists public.transactions (
  user_id     uuid not null references auth.users (id) on delete cascade,
  id          text not null,
  type        text not null check (type in ('income', 'expense', 'savings')),
  category    text not null,
  amount      numeric(14,2) not null check (amount > 0),
  date        timestamptz not null,
  note        text,
  goal_id     text,
  created_at  timestamptz not null default now(),
  primary key (user_id, id),
  foreign key (user_id, goal_id)
    references public.savings_goals (user_id, id) on delete set null (goal_id)
);
create index if not exists transactions_user_date_idx
  on public.transactions (user_id, date desc);

-- ---------- budgets (spent is derived in the app, never stored) -------
create table if not exists public.budgets (
  user_id       uuid not null references auth.users (id) on delete cascade,
  id            text not null,
  category      text not null,
  limit_amount  numeric(14,2) not null check (limit_amount > 0),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  primary key (user_id, id),
  unique (user_id, category)
);

-- ---------- upcoming_items (shown on Home) ----------------------------
create table if not exists public.upcoming_items (
  user_id     uuid not null references auth.users (id) on delete cascade,
  id          text not null,
  name        text not null,
  amount      numeric(14,2) not null check (amount > 0),
  is_expense  boolean not null,
  date        timestamptz not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, id)
);

-- ---------- user_missions (templates stay predefined in the app) ------
create table if not exists public.user_missions (
  user_id         uuid not null references auth.users (id) on delete cascade,
  mission_id      text not null,                      -- "<date>_<templateId>"
  template_id     text not null,
  mission_date    date not null,
  completed       boolean not null default false,
  reward_granted  boolean not null default false,
  completed_at    timestamptz,
  created_at      timestamptz not null default now(),
  primary key (user_id, mission_id),
  unique (user_id, mission_date, template_id)         -- one row per mission per day
);

-- ---------- user_achievements -----------------------------------------
create table if not exists public.user_achievements (
  user_id         uuid not null references auth.users (id) on delete cascade,
  achievement_id  text not null,
  unlocked        boolean not null default true,
  unlocked_at     timestamptz not null default now(),
  primary key (user_id, achievement_id)               -- can only unlock once
);

-- ---------- user_customizations (owned + equipped Bucks items) --------
create table if not exists public.user_customizations (
  user_id      uuid not null references auth.users (id) on delete cascade,
  item_id      text not null,
  category     text not null,
  equipped     boolean not null default false,
  acquired_at  timestamptz not null default now(),
  primary key (user_id, item_id)                      -- can only own an item once
);
-- only one equipped item per category per user
create unique index if not exists user_customizations_one_equipped_idx
  on public.user_customizations (user_id, category) where equipped;

-- ---------- updated_at triggers ---------------------------------------
do $$
declare t text;
begin
  foreach t in array array['profiles','user_stats','savings_goals','budgets'] loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format(
      'create trigger set_updated_at before update on public.%I
         for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- A reward/completion flag can never be switched back off once granted.
create or replace function public.keep_mission_rewards()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.completed      := old.completed or new.completed;
  new.reward_granted := old.reward_granted or new.reward_granted;
  return new;
end;
$$;
drop trigger if exists keep_mission_rewards on public.user_missions;
create trigger keep_mission_rewards before update on public.user_missions
  for each row execute function public.keep_mission_rewards();

-- ---------- new-user bootstrap ----------------------------------------
-- Runs inside Supabase when auth.users gets a row, so a profile + stats
-- row exist even when email confirmation delays the first session.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  uname text;
begin
  uname := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'username', '')), '');
  insert into public.profiles (id, username)
  values (new.id, left(coalesce(uname, 'Student'), 40))
  on conflict (id) do nothing;

  insert into public.user_stats (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- ROW LEVEL SECURITY ----------------------------------------
-- Every user-owned table: a signed-in user can only touch rows whose
-- owner is their own auth.uid().
do $$
declare t text;
begin
  foreach t in array array[
    'transactions','budgets','savings_goals','upcoming_items',
    'user_missions','user_achievements','user_stats','user_customizations'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "%1$s_select_own" on public.%1$I', t);
    execute format('drop policy if exists "%1$s_insert_own" on public.%1$I', t);
    execute format('drop policy if exists "%1$s_update_own" on public.%1$I', t);
    execute format('drop policy if exists "%1$s_delete_own" on public.%1$I', t);
    execute format('create policy "%1$s_select_own" on public.%1$I
                    for select to authenticated using ((select auth.uid()) = user_id)', t);
    execute format('create policy "%1$s_insert_own" on public.%1$I
                    for insert to authenticated with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "%1$s_update_own" on public.%1$I
                    for update to authenticated using ((select auth.uid()) = user_id)
                    with check ((select auth.uid()) = user_id)', t);
    execute format('create policy "%1$s_delete_own" on public.%1$I
                    for delete to authenticated using ((select auth.uid()) = user_id)', t);
  end loop;
end $$;

-- profiles is keyed by id (= auth.users.id)
alter table public.profiles enable row level security;
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles
  for update to authenticated using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);
create policy "profiles_delete_own" on public.profiles
  for delete to authenticated using ((select auth.uid()) = id);

-- Nothing here is readable by anonymous (not signed in) visitors.
revoke all on all tables in schema public from anon;

-- ---------- BucksBoard (public leaderboard, prepared) -----------------
-- The ONLY cross-user data. It exposes just username + progression
-- numbers. No email, transactions, budgets or savings are included.
-- Runs with the view owner's rights on purpose (so it can rank everyone);
-- that is why it selects only these safe columns.
create or replace view public.bucksboard as
select
  p.id                                         as user_id,
  p.username                                   as username,
  s.xp                                         as xp,
  s.bucks_coins                                as bucks_coins,
  s.current_streak                             as current_streak,
  (select count(*) from public.user_achievements a
    where a.user_id = p.id and a.unlocked)     as achievements_unlocked,
  rank() over (order by s.xp desc)             as rank
from public.profiles p
join public.user_stats s on s.user_id = p.id;

revoke all on public.bucksboard from anon, authenticated;
grant select on public.bucksboard to authenticated;
