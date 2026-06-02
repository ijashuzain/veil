drop policy if exists "film_entries_select_public_diary"
on public.film_entries;
create policy "film_entries_select_public_diary"
on public.film_entries for select
to authenticated
using (watched_on is not null or in_watchlist = true or is_favorite = true);
