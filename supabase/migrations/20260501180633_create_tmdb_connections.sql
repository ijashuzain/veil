create table if not exists public.tmdb_connections (
  user_id uuid primary key references auth.users(id) on delete cascade,
  account_id integer not null,
  username text not null default '',
  name text not null default '',
  session_id text not null,
  avatar_path text,
  linked_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.tmdb_connections enable row level security;

drop policy if exists "tmdb_connections_select_own"
on public.tmdb_connections;
create policy "tmdb_connections_select_own"
on public.tmdb_connections for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "tmdb_connections_insert_own"
on public.tmdb_connections;
create policy "tmdb_connections_insert_own"
on public.tmdb_connections for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "tmdb_connections_update_own"
on public.tmdb_connections;
create policy "tmdb_connections_update_own"
on public.tmdb_connections for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "tmdb_connections_delete_own"
on public.tmdb_connections;
create policy "tmdb_connections_delete_own"
on public.tmdb_connections for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);
