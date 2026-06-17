create table if not exists public.user_blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id),
  check (blocker_id <> blocked_user_id)
);

create index if not exists user_blocks_blocked_user_id_idx
on public.user_blocks (blocked_user_id);

alter table public.user_blocks enable row level security;

drop policy if exists "user_blocks_select_own" on public.user_blocks;
create policy "user_blocks_select_own"
on public.user_blocks for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = blocker_id);

drop policy if exists "user_blocks_insert_own" on public.user_blocks;
create policy "user_blocks_insert_own"
on public.user_blocks for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = blocker_id);

drop policy if exists "user_blocks_delete_own" on public.user_blocks;
create policy "user_blocks_delete_own"
on public.user_blocks for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = blocker_id);

create table if not exists public.community_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('profile', 'review', 'comment')),
  target_user_id uuid references auth.users(id) on delete set null,
  content_id text not null default '',
  parent_content_id text,
  reason text not null,
  details text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists community_reports_reporter_created_idx
on public.community_reports (reporter_id, created_at desc);

create index if not exists community_reports_target_created_idx
on public.community_reports (target_user_id, created_at desc);

alter table public.community_reports enable row level security;

drop policy if exists "community_reports_select_own" on public.community_reports;
create policy "community_reports_select_own"
on public.community_reports for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = reporter_id);

drop policy if exists "community_reports_insert_own" on public.community_reports;
create policy "community_reports_insert_own"
on public.community_reports for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = reporter_id);
