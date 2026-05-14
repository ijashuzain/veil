alter table public.user_profiles
add column if not exists is_deleted boolean not null default false,
add column if not exists deleted_at timestamptz,
add column if not exists deletion_reason text;

drop policy if exists "user_profiles_select_deleted_profiles"
on public.user_profiles;
create policy "user_profiles_select_deleted_profiles"
on public.user_profiles for select
to authenticated
using (is_deleted = true);

create or replace function public.delete_current_account(delete_reason text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  insert into public.user_profiles (user_id)
  values (current_user_id)
  on conflict (user_id) do nothing;

  update public.user_profiles
  set
    is_deleted = true,
    deleted_at = now(),
    deletion_reason = left(coalesce(delete_reason, ''), 500),
    updated_at = now()
  where user_id = current_user_id;

  delete from public.user_follows
  where follower_id = current_user_id
     or following_id = current_user_id;

  delete from public.film_entries
  where user_id = current_user_id
    and trim(coalesce(review, '')) = '';

  update public.film_entries
  set
    watched_on = null,
    is_favorite = false,
    in_watchlist = false,
    liked = false,
    updated_at = now()
  where user_id = current_user_id
    and trim(coalesce(review, '')) <> '';
end;
$$;

revoke execute on function public.delete_current_account(text) from public;
revoke execute on function public.delete_current_account(text) from anon;
grant execute on function public.delete_current_account(text) to authenticated;
