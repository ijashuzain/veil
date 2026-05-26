create table if not exists public.review_comments (
  id uuid primary key default gen_random_uuid(),
  review_user_id uuid not null,
  review_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  parent_comment_id uuid references public.review_comments(id) on delete cascade,
  body text not null,
  is_spoiler boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.review_comments
add column if not exists parent_comment_id uuid references public.review_comments(id) on delete cascade;

alter table public.review_comments
add column if not exists is_spoiler boolean not null default false;

create index if not exists review_comments_parent_comment_id_idx
on public.review_comments (parent_comment_id);

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

create table if not exists public.review_reactions (
  review_user_id uuid not null,
  review_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  reaction_type text not null check (reaction_type in ('helpful')),
  created_at timestamptz not null default now(),
  primary key (review_user_id, review_id, user_id, reaction_type)
);

create index if not exists review_reactions_user_id_idx
on public.review_reactions (user_id);

alter table public.review_reactions enable row level security;

drop policy if exists "review_reactions_select_all" on public.review_reactions;
create policy "review_reactions_select_all"
on public.review_reactions for select
to authenticated
using (true);

drop policy if exists "review_reactions_insert_own" on public.review_reactions;
create policy "review_reactions_insert_own"
on public.review_reactions for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "review_reactions_delete_own" on public.review_reactions;
create policy "review_reactions_delete_own"
on public.review_reactions for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);
