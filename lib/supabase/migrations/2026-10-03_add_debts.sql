-- BUCKS: add the Debt Tracker table.
-- SAFE to run on your live project: it only ADDS the debts table, one
-- trigger function, and the debts policies. It does not touch, reset or
-- drop any existing table or data, and it can be re-run.
-- Run in: Supabase Dashboard > SQL Editor > New query.
-- (The same definitions are also in lib/supabase/schema.sql.)

create table if not exists public.debts (
  user_id          uuid not null references auth.users (id) on delete cascade,
  id               text not null,
  type             text not null check (type in ('i_owe', 'owed_to_me')),
  title            text not null check (char_length(btrim(title)) > 0),
  person_name      text check (person_name is null or char_length(btrim(person_name)) > 0),
  original_amount  numeric(14,2) not null check (original_amount > 0),
  amount_paid      numeric(14,2) not null default 0 check (amount_paid >= 0),
  due_date         date,
  notes            text,
  status           text not null default 'active' check (status in ('active', 'paid')),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  primary key (user_id, id),
  check (amount_paid <= original_amount)
);
create index if not exists debts_user_status_due_idx
  on public.debts (user_id, status, due_date);

-- status follows the amounts: paid exactly when amount_paid >= original_amount
create or replace function public.sync_debt_status()
returns trigger language plpgsql
set search_path = public
as $$
begin
  new.status := case when new.amount_paid >= new.original_amount
                     then 'paid' else 'active' end;
  return new;
end;
$$;
drop trigger if exists sync_debt_status on public.debts;
create trigger sync_debt_status before insert or update on public.debts
  for each row execute function public.sync_debt_status();

-- uses the existing public.set_updated_at() helper
drop trigger if exists set_updated_at on public.debts;
create trigger set_updated_at before update on public.debts
  for each row execute function public.set_updated_at();

-- Row Level Security: a user can only touch their own debts.
alter table public.debts enable row level security;
drop policy if exists "debts_select_own" on public.debts;
drop policy if exists "debts_insert_own" on public.debts;
drop policy if exists "debts_update_own" on public.debts;
drop policy if exists "debts_delete_own" on public.debts;
create policy "debts_select_own" on public.debts
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "debts_insert_own" on public.debts
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "debts_update_own" on public.debts
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "debts_delete_own" on public.debts
  for delete to authenticated using ((select auth.uid()) = user_id);

-- not readable by signed-out visitors
revoke all on public.debts from anon;
