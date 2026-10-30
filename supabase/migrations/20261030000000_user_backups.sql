create table if not exists public.user_backups (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null
    check (jsonb_typeof(data) = 'object'),
  updated_at timestamptz not null default now()
);

alter table public.user_backups enable row level security;

revoke all on table public.user_backups from anon;
revoke all on table public.user_backups from authenticated;
grant select, insert, update, delete
  on table public.user_backups to authenticated;

drop policy if exists "Users manage their own backup"
  on public.user_backups;

create policy "Users manage their own backup"
  on public.user_backups
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
