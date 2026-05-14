# Movie Suggestions And Social Alerts Design

## Goal

Add a social suggestion flow where a user can suggest a movie or show to one or more followers, and extend Alerts with follow request/acceptance activity plus a dedicated Suggestions tab.

## Scope

- Add `Suggest` under `Review` in the detail social action sheet.
- Open a follower multi-select sheet and send the selected users a movie suggestion.
- Show suggestions in Alerts under a new `Suggestions` tab.
- Tapping a suggestion opens the suggested title detail page.
- Change follow from immediate local/social follow into a request flow.
- Show incoming follow requests in Alerts with accept/decline actions.
- Show accepted follow requests in Alerts for the requester.
- Fix member search so users can be found by display name, not only by review-derived user ids.
- Document Supabase SQL changes needed for profile search, suggestions, and follow requests.

## Architecture

The existing `SocialRepository` remains the source of truth for social data. It gains focused methods for profile search, movie suggestions, and follow requests, with Supabase implementations and local SharedPreferences fallbacks for tests/offline operation.

`AlertsViewModel` will combine current TMDB alerts with social follow alerts and suggestions. The Alerts UI will keep the existing card language and add a compact tab switcher like Diary/Profile.

The detail screen will only coordinate UI flow. It opens the existing social action sheet, then a second follower selector sheet for the suggestion send action.

## Data Model

`movie_suggestions` stores a snapshot of the suggested content:

- sender and recipient ids
- sender display name
- TMDB/IMDb ids and media type
- title, year, poster/backdrop/description metadata
- created/read timestamps

`follow_requests` stores request status:

- requester and recipient ids
- requester/recipient display name snapshots
- status: `pending`, `accepted`, or `declined`
- created/responded timestamps

`user_profiles` gains public-searchable display metadata through security-definer RPCs instead of broad table exposure.

## UX

The detail sheet gains:

- `Review`
- `Suggest`

The follower selector sheet shows followers with checkbox selection and a disabled `Suggest` button until at least one user is selected.

Alerts gains two tabs:

- `Alerts`: follow requests, accepted follow notifications, and TMDB alerts.
- `Suggestions`: movie suggestion rows with poster thumbnail and “User A suggested Movie A for you.”

## Error Handling

- Suggesting with no followers shows an empty state.
- Failed sends keep the sheet open and show a toast/snackbar.
- Follow request accept/decline failures leave the alert in place.
- TMDB alert failures should not erase social suggestions if social data loads.

## Supabase SQL

```sql
alter table public.user_profiles
add column if not exists display_name text not null default '',
add column if not exists avatar_url text,
add column if not exists is_deleted boolean not null default false;

update public.user_profiles p
set display_name = coalesce(
  nullif(trim(u.raw_user_meta_data->>'display_name'), ''),
  nullif(trim(u.raw_user_meta_data->>'full_name'), ''),
  nullif(split_part(u.email, '@', 1), ''),
  ''
)
from auth.users u
where p.user_id = u.id
  and coalesce(p.display_name, '') = '';

create or replace function public.search_user_profiles(search_query text, max_results integer default 20)
returns table(user_id uuid, display_name text, avatar_url text)
language sql
security definer
set search_path = public
stable
as $$
  select p.user_id, coalesce(nullif(p.display_name, ''), 'Veil member'), p.avatar_url
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

grant execute on function public.search_user_profiles(text, integer) to authenticated;

create or replace function public.user_profiles_by_ids(profile_ids uuid[])
returns table(user_id uuid, display_name text, avatar_url text)
language sql
security definer
set search_path = public
stable
as $$
  select p.user_id, coalesce(nullif(p.display_name, ''), 'Veil member'), p.avatar_url
  from public.user_profiles p
  where auth.uid() is not null
    and p.is_deleted = false
    and p.user_id = any(profile_ids);
$$;

grant execute on function public.user_profiles_by_ids(uuid[]) to authenticated;

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

drop policy if exists "movie_suggestions_select_participants" on public.movie_suggestions;
create policy "movie_suggestions_select_participants"
on public.movie_suggestions for select
to authenticated
using (auth.uid() = sender_id or auth.uid() = recipient_id);

drop policy if exists "movie_suggestions_insert_to_followers" on public.movie_suggestions;
create policy "movie_suggestions_insert_to_followers"
on public.movie_suggestions for insert
to authenticated
with check (
  auth.uid() = sender_id
  and exists (
    select 1 from public.user_follows f
    where f.follower_id = recipient_id
      and f.following_id = sender_id
  )
);

drop policy if exists "movie_suggestions_update_recipient" on public.movie_suggestions;
create policy "movie_suggestions_update_recipient"
on public.movie_suggestions for update
to authenticated
using (auth.uid() = recipient_id)
with check (auth.uid() = recipient_id);

create table if not exists public.follow_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  requester_display_name text not null default '',
  recipient_display_name text not null default '',
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  unique (requester_id, recipient_id),
  check (requester_id <> recipient_id)
);

create index if not exists follow_requests_recipient_status_idx
on public.follow_requests (recipient_id, status, created_at desc);

alter table public.follow_requests enable row level security;

drop policy if exists "follow_requests_select_participants" on public.follow_requests;
create policy "follow_requests_select_participants"
on public.follow_requests for select
to authenticated
using (auth.uid() = requester_id or auth.uid() = recipient_id);

drop policy if exists "follow_requests_insert_own" on public.follow_requests;
create policy "follow_requests_insert_own"
on public.follow_requests for insert
to authenticated
with check (auth.uid() = requester_id and status = 'pending');

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

grant execute on function public.accept_follow_request(uuid) to authenticated;
```

## Test Plan

- Repository tests for local profile search by display name.
- Repository tests for follow request pending and accepted states.
- Repository tests for suggesting content to followers and listing suggestions for the recipient.
- View model tests for combined TMDB alerts, follow alerts, and suggestions.
- Widget tests for Alerts tabs and detail sheet `Suggest` entry.
