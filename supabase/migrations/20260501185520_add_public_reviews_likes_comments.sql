drop policy if exists "film_entries_select_public_reviews"
on public.film_entries;
create policy "film_entries_select_public_reviews"
on public.film_entries for select
to authenticated
using (review <> '');

create table if not exists public.review_likes (
  review_user_id uuid not null,
  review_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_user_id, review_id, user_id)
);

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
