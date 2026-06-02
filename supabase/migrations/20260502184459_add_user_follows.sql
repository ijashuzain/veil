create table if not exists public.user_follows (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index if not exists user_follows_following_id_idx
on public.user_follows (following_id);

alter table public.user_follows enable row level security;

drop policy if exists "user_follows_select_all" on public.user_follows;
create policy "user_follows_select_all"
on public.user_follows for select
to authenticated
using (true);

drop policy if exists "user_follows_insert_own" on public.user_follows;
create policy "user_follows_insert_own"
on public.user_follows for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = follower_id);

drop policy if exists "user_follows_delete_own" on public.user_follows;
create policy "user_follows_delete_own"
on public.user_follows for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = follower_id);
