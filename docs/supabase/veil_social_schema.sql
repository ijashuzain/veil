create table if not exists public.film_entries (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  tmdb_id integer,
  imdb_id text,
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
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.film_entries enable row level security;

drop policy if exists "film_entries_select_public_reviews"
on public.film_entries;
drop policy if exists "film_entries_select_public_diary"
on public.film_entries;
drop policy if exists "film_entries_select_own"
on public.film_entries;
drop policy if exists "film_entries_select_visible"
on public.film_entries;
create policy "film_entries_select_visible"
on public.film_entries for select
to authenticated
using (
  ((select auth.uid()) is not null and (select auth.uid()) = user_id)
  or review <> ''
  or watched_on is not null
  or in_watchlist = true
  or is_favorite = true
);

drop policy if exists "film_entries_insert_own"
on public.film_entries;
create policy "film_entries_insert_own"
on public.film_entries for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "film_entries_update_own"
on public.film_entries;
create policy "film_entries_update_own"
on public.film_entries for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "film_entries_delete_own"
on public.film_entries;
create policy "film_entries_delete_own"
on public.film_entries for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create index if not exists film_entries_user_watched_idx
on public.film_entries (user_id, watched_on desc nulls last);

create index if not exists film_entries_user_flags_idx
on public.film_entries (user_id, in_watchlist, is_favorite);

create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  is_premium boolean not null default false,
  is_deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles
add column if not exists display_name text not null default '',
add column if not exists avatar_url text,
add column if not exists is_deleted boolean not null default false;

alter table public.user_profiles enable row level security;

drop policy if exists "user_profiles_select_own"
on public.user_profiles;
create policy "user_profiles_select_own"
on public.user_profiles for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (user_id, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'display_name'), ''),
      nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
      nullif(trim(new.raw_user_meta_data->>'name'), ''),
      nullif(split_part(new.email, '@', 1), ''),
      ''
    ),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

revoke execute on function public.handle_new_user_profile() from public;
revoke execute on function public.handle_new_user_profile() from anon;
revoke execute on function public.handle_new_user_profile() from authenticated;

insert into public.user_profiles (user_id)
select id from auth.users
on conflict (user_id) do nothing;

update public.user_profiles p
set display_name = coalesce(
  nullif(trim(u.raw_user_meta_data->>'display_name'), ''),
  nullif(trim(u.raw_user_meta_data->>'full_name'), ''),
  nullif(trim(u.raw_user_meta_data->>'name'), ''),
  nullif(split_part(u.email, '@', 1), ''),
  ''
)
from auth.users u
where p.user_id = u.id
  and coalesce(p.display_name, '') = '';

create or replace function public.search_user_profiles(
  search_query text,
  max_results integer default 20
)
returns table(user_id uuid, display_name text, avatar_url text)
language sql
security definer
set search_path = public
stable
as $$
  select
    p.user_id,
    coalesce(nullif(p.display_name, ''), 'Veil member') as display_name,
    p.avatar_url
  from public.user_profiles p
  where auth.uid() is not null
    and p.is_deleted = false
    and (
      trim(coalesce(search_query, '')) = ''
      or p.display_name ilike '%' || trim(search_query) || '%'
      or p.user_id::text ilike '%' || trim(search_query) || '%'
    )
  order by lower(p.display_name), p.created_at desc
  limit least(greatest(coalesce(max_results, 20), 1), 50);
$$;

revoke execute on function public.search_user_profiles(text, integer) from public;
revoke execute on function public.search_user_profiles(text, integer) from anon;
grant execute on function public.search_user_profiles(text, integer) to authenticated;

create or replace function public.user_profiles_by_ids(profile_ids uuid[])
returns table(user_id uuid, display_name text, avatar_url text)
language sql
security definer
set search_path = public
stable
as $$
  select
    p.user_id,
    coalesce(nullif(p.display_name, ''), 'Veil member') as display_name,
    p.avatar_url
  from public.user_profiles p
  where auth.uid() is not null
    and p.is_deleted = false
    and p.user_id = any(profile_ids);
$$;

revoke execute on function public.user_profiles_by_ids(uuid[]) from public;
revoke execute on function public.user_profiles_by_ids(uuid[]) from anon;
grant execute on function public.user_profiles_by_ids(uuid[]) to authenticated;

create table if not exists public.review_likes (
  review_user_id uuid not null,
  review_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_user_id, review_id, user_id)
);

create index if not exists review_likes_user_id_idx
on public.review_likes (user_id);

alter table public.review_likes enable row level security;

drop policy if exists "review_likes_select_all" on public.review_likes;
create policy "review_likes_select_all"
on public.review_likes for select
to authenticated
using (true);

drop policy if exists "review_likes_insert_own" on public.review_likes;
create policy "review_likes_insert_own"
on public.review_likes for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "review_likes_delete_own" on public.review_likes;
create policy "review_likes_delete_own"
on public.review_likes for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create table if not exists public.review_comments (
  id uuid primary key default gen_random_uuid(),
  review_user_id uuid not null,
  review_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

create index if not exists review_comments_user_id_idx
on public.review_comments (user_id);

alter table public.review_comments enable row level security;

drop policy if exists "review_comments_select_all" on public.review_comments;
create policy "review_comments_select_all"
on public.review_comments for select
to authenticated
using (true);

drop policy if exists "review_comments_insert_own" on public.review_comments;
create policy "review_comments_insert_own"
on public.review_comments for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

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

create table if not exists public.movie_suggestions (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  sender_display_name text not null default '',
  content_id text not null default '',
  tmdb_id integer,
  imdb_id text,
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
  created_at timestamptz not null default now(),
  read_at timestamptz,
  check (sender_id <> recipient_id)
);

create index if not exists movie_suggestions_recipient_created_idx
on public.movie_suggestions (recipient_id, created_at desc);

alter table public.movie_suggestions enable row level security;

drop policy if exists "movie_suggestions_select_participants"
on public.movie_suggestions;
create policy "movie_suggestions_select_participants"
on public.movie_suggestions for select
to authenticated
using ((select auth.uid()) = sender_id or (select auth.uid()) = recipient_id);

drop policy if exists "movie_suggestions_insert_to_followers"
on public.movie_suggestions;
create policy "movie_suggestions_insert_to_followers"
on public.movie_suggestions for insert
to authenticated
with check (
  (select auth.uid()) = sender_id
  and exists (
    select 1 from public.user_follows f
    where f.follower_id = recipient_id
      and f.following_id = sender_id
  )
);

drop policy if exists "movie_suggestions_update_recipient"
on public.movie_suggestions;
create policy "movie_suggestions_update_recipient"
on public.movie_suggestions for update
to authenticated
using ((select auth.uid()) = recipient_id)
with check ((select auth.uid()) = recipient_id);

create table if not exists public.follow_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  requester_display_name text not null default '',
  recipient_display_name text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (requester_id, recipient_id),
  check (requester_id <> recipient_id)
);

create index if not exists follow_requests_recipient_status_idx
on public.follow_requests (recipient_id, status, created_at desc);

alter table public.follow_requests enable row level security;

drop policy if exists "follow_requests_select_participants"
on public.follow_requests;
create policy "follow_requests_select_participants"
on public.follow_requests for select
to authenticated
using ((select auth.uid()) = requester_id or (select auth.uid()) = recipient_id);

drop policy if exists "follow_requests_insert_own"
on public.follow_requests;
create policy "follow_requests_insert_own"
on public.follow_requests for insert
to authenticated
with check ((select auth.uid()) = requester_id and status = 'pending');

drop policy if exists "follow_requests_delete_requester"
on public.follow_requests;
create policy "follow_requests_delete_requester"
on public.follow_requests for delete
to authenticated
using ((select auth.uid()) = requester_id);

create or replace function public.accept_follow_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester uuid;
begin
  update public.follow_requests
  set status = 'accepted', responded_at = now()
  where id = request_id
    and recipient_id = auth.uid()
    and status = 'pending'
  returning requester_id into requester;

  if requester is null then
    raise exception 'follow_request_not_found';
  end if;

  insert into public.user_follows (follower_id, following_id)
  values (requester, auth.uid())
  on conflict do nothing;
end;
$$;

revoke execute on function public.accept_follow_request(uuid) from public;
revoke execute on function public.accept_follow_request(uuid) from anon;
grant execute on function public.accept_follow_request(uuid) to authenticated;
