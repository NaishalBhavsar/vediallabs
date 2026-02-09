-- Enable required extension for UUID generation if needed
create extension if not exists pgcrypto;

-- ==============
-- Tables
-- ==============

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  type text not null check (type in ('ppt', 'video')),
  topic text not null,                -- e.g., 'rag', 'retrieval augmented generation'
  bucket text not null,               -- e.g., 'learning-content'
  object_path text not null,          -- e.g., 'ppt/rag-intro.pptx'
  created_at timestamptz not null default now()
);

create table if not exists public.queries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  query_text text not null,
  normalized_query text not null,
  matched_resource_ids uuid[] not null default '{}',
  answer_text text not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_resources_user_topic on public.resources(user_id, topic);
create index if not exists idx_queries_user_created on public.queries(user_id, created_at);

-- ==============
-- RLS
-- ==============

alter table public.profiles enable row level security;
alter table public.resources enable row level security;
alter table public.queries enable row level security;

-- Profiles: user can read/update own profile
create policy "profiles_select_own"
on public.profiles for select
using (auth.uid() = id);

create policy "profiles_update_own"
on public.profiles for update
using (auth.uid() = id);

-- Resources: user can CRUD only their resources
create policy "resources_select_own"
on public.resources for select
using (auth.uid() = user_id);

create policy "resources_insert_own"
on public.resources for insert
with check (auth.uid() = user_id);

create policy "resources_update_own"
on public.resources for update
using (auth.uid() = user_id);

create policy "resources_delete_own"
on public.resources for delete
using (auth.uid() = user_id);

-- Queries: user can read/insert only their own query history
create policy "queries_select_own"
on public.queries for select
using (auth.uid() = user_id);

create policy "queries_insert_own"
on public.queries for insert
with check (auth.uid() = user_id);

-- Optional: prevent updates/deletes for queries (audit log style)
revoke update, delete on public.queries from anon, authenticated;

-- ==============
-- Helpful trigger: create profile row on signup (optional but nice)
-- ==============

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles(id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();
