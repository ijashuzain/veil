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

create index if not exists review_likes_user_id_idx
on public.review_likes (user_id);

create index if not exists review_comments_user_id_idx
on public.review_comments (user_id);
