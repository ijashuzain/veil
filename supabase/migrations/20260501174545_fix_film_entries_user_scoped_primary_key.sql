alter table public.film_entries drop constraint if exists film_entries_pkey;
alter table public.film_entries add constraint film_entries_pkey primary key (user_id, id);
