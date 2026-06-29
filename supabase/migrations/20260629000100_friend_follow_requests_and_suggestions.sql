alter table public.follow_requests
add column if not exists accepted_notice_read_at timestamptz;

create index if not exists follow_requests_requester_accepted_notice_idx
on public.follow_requests (requester_id, status, accepted_notice_read_at, responded_at desc);

create or replace function public.social_relationship_blocked(
  left_user uuid,
  right_user uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if auth.uid() is null then
    return true;
  end if;

  if left_user is null or right_user is null then
    return true;
  end if;

  if auth.uid() <> left_user and auth.uid() <> right_user then
    raise exception 'relationship_check_not_allowed';
  end if;

  return exists (
      select 1
      from public.user_blocks b
      where (b.blocker_id = left_user and b.blocked_user_id = right_user)
         or (b.blocker_id = right_user and b.blocked_user_id = left_user)
  );
end;
$$;

revoke execute on function public.social_relationship_blocked(uuid, uuid) from public;
revoke execute on function public.social_relationship_blocked(uuid, uuid) from anon;
grant execute on function public.social_relationship_blocked(uuid, uuid) to authenticated;

drop policy if exists "user_follows_insert_own" on public.user_follows;
drop policy if exists "user_follows_delete_own" on public.user_follows;

drop policy if exists "follow_requests_insert_own" on public.follow_requests;
drop policy if exists "follow_requests_delete_requester" on public.follow_requests;

drop policy if exists "movie_suggestions_insert_to_followers"
on public.movie_suggestions;
create policy "movie_suggestions_insert_to_friends"
on public.movie_suggestions for insert
to authenticated
with check (
  (select auth.uid()) = sender_id
  and sender_id <> recipient_id
  and not public.social_relationship_blocked(sender_id, recipient_id)
  and exists (
    select 1 from public.user_follows f
    where f.follower_id = sender_id
      and f.following_id = recipient_id
  )
  and exists (
    select 1 from public.user_follows f
    where f.follower_id = recipient_id
      and f.following_id = sender_id
  )
);

create or replace function public.request_follow_user(
  target_user_id uuid,
  requester_display_name text default '',
  recipient_display_name text default ''
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  viewer uuid := auth.uid();
  existing_status text;
  target_follows_viewer boolean;
  viewer_follows_target boolean;
begin
  if viewer is null then
    raise exception 'not_authenticated';
  end if;

  if target_user_id is null or target_user_id = viewer then
    return 'none';
  end if;

  if public.social_relationship_blocked(viewer, target_user_id) then
    raise exception 'relationship_blocked';
  end if;

  select exists (
    select 1 from public.user_follows f
    where f.follower_id = viewer
      and f.following_id = target_user_id
  ) into viewer_follows_target;

  if viewer_follows_target then
    select exists (
      select 1 from public.user_follows f
      where f.follower_id = target_user_id
        and f.following_id = viewer
    ) into target_follows_viewer;
    return case when target_follows_viewer then 'friends' else 'following' end;
  end if;

  select exists (
    select 1 from public.user_follows f
    where f.follower_id = target_user_id
      and f.following_id = viewer
  ) into target_follows_viewer;

  if target_follows_viewer then
    insert into public.user_follows (follower_id, following_id)
    values (viewer, target_user_id)
    on conflict do nothing;
    return 'friends';
  end if;

  select status into existing_status
  from public.follow_requests
  where requester_id = viewer
    and recipient_id = target_user_id;

  if existing_status = 'pending' then
    return 'requested';
  end if;

  insert into public.follow_requests (
    requester_id,
    recipient_id,
    requester_display_name,
    recipient_display_name,
    status,
    created_at,
    responded_at,
    accepted_notice_read_at
  ) values (
    viewer,
    target_user_id,
    coalesce(requester_display_name, ''),
    coalesce(recipient_display_name, ''),
    'pending',
    now(),
    null,
    null
  )
  on conflict (requester_id, recipient_id) do update
  set requester_display_name = excluded.requester_display_name,
      recipient_display_name = excluded.recipient_display_name,
      status = 'pending',
      created_at = now(),
      responded_at = null,
      accepted_notice_read_at = null;

  return 'requested';
end;
$$;

revoke execute on function public.request_follow_user(uuid, text, text) from public;
revoke execute on function public.request_follow_user(uuid, text, text) from anon;
grant execute on function public.request_follow_user(uuid, text, text) to authenticated;

create or replace function public.accept_follow_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  requester uuid;
  recipient uuid := auth.uid();
begin
  if recipient is null then
    raise exception 'not_authenticated';
  end if;

  select requester_id into requester
  from public.follow_requests
  where id = request_id
    and recipient_id = recipient
    and status = 'pending'
  for update;

  if requester is null then
    raise exception 'follow_request_not_found';
  end if;

  if public.social_relationship_blocked(requester, recipient) then
    raise exception 'relationship_blocked';
  end if;

  update public.follow_requests
  set status = 'accepted',
      responded_at = now(),
      accepted_notice_read_at = null
  where id = request_id
    and recipient_id = recipient
    and status = 'pending';

  insert into public.user_follows (follower_id, following_id)
  values (requester, recipient)
  on conflict do nothing;
end;
$$;

revoke execute on function public.accept_follow_request(uuid) from public;
revoke execute on function public.accept_follow_request(uuid) from anon;
grant execute on function public.accept_follow_request(uuid) to authenticated;

create or replace function public.decline_follow_request(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.follow_requests
  set status = 'declined',
      responded_at = now(),
      accepted_notice_read_at = null
  where id = request_id
    and recipient_id = auth.uid()
    and status = 'pending';

  if not found then
    raise exception 'follow_request_not_found';
  end if;
end;
$$;

revoke execute on function public.decline_follow_request(uuid) from public;
revoke execute on function public.decline_follow_request(uuid) from anon;
grant execute on function public.decline_follow_request(uuid) to authenticated;

create or replace function public.cancel_follow_request(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  delete from public.follow_requests
  where requester_id = auth.uid()
    and recipient_id = target_user_id
    and status = 'pending';
end;
$$;

revoke execute on function public.cancel_follow_request(uuid) from public;
revoke execute on function public.cancel_follow_request(uuid) from anon;
grant execute on function public.cancel_follow_request(uuid) to authenticated;

create or replace function public.unfollow_user(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  delete from public.user_follows
  where follower_id = auth.uid()
    and following_id = target_user_id;
end;
$$;

revoke execute on function public.unfollow_user(uuid) from public;
revoke execute on function public.unfollow_user(uuid) from anon;
grant execute on function public.unfollow_user(uuid) to authenticated;

create or replace function public.mark_follow_request_notice_read(request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  update public.follow_requests
  set accepted_notice_read_at = coalesce(accepted_notice_read_at, now())
  where id = request_id
    and requester_id = auth.uid()
    and status = 'accepted';
end;
$$;

revoke execute on function public.mark_follow_request_notice_read(uuid) from public;
revoke execute on function public.mark_follow_request_notice_read(uuid) from anon;
grant execute on function public.mark_follow_request_notice_read(uuid) to authenticated;
