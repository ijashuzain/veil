create table if not exists public.film_entries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  tmdb_id integer,
  media_type text not null default 'movie',
  title text not null,
  subtitle text not null default '',
  year integer not null default 0,
  genre text not null default '',
  type text not null default 'Movie',
  tmdb_rating numeric not null default 0,
  poster_url text,
  backdrop_url text,
  description text not null default '',
  rating numeric not null default 0,
  review text not null default '',
  tags text[] not null default '{}',
  watched_on timestamptz,
  is_favorite boolean not null default false,
  in_watchlist boolean not null default false,
  liked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.film_entries enable row level security;

drop policy if exists "film_entries_select_own" on public.film_entries;
drop policy if exists "film_entries_insert_own" on public.film_entries;
drop policy if exists "film_entries_update_own" on public.film_entries;
drop policy if exists "film_entries_delete_own" on public.film_entries;

create policy "film_entries_select_own"
on public.film_entries for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "film_entries_insert_own"
on public.film_entries for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "film_entries_update_own"
on public.film_entries for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy "film_entries_delete_own"
on public.film_entries for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create index if not exists film_entries_user_watched_idx
on public.film_entries (user_id, watched_on desc nulls last);

create index if not exists film_entries_user_flags_idx
on public.film_entries (user_id, in_watchlist, is_favorite);
