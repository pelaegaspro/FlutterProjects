create extension if not exists "uuid-ossp";

create table if not exists groups (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  created_by uuid not null references auth.users(id),
  created_at timestamp with time zone default now()
);

create table if not exists group_members (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  joined_at timestamp with time zone default now(),
  unique (group_id, user_id)
);

create table if not exists messages (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  message text not null,
  created_at timestamp with time zone default now()
);

create table if not exists group_leaderboard (
  id uuid primary key default uuid_generate_v4(),
  group_id uuid not null references groups(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  points int default 0,
  unique (group_id, user_id)
);

create index if not exists idx_group_members_user_id on group_members(user_id);
create index if not exists idx_group_members_group_id on group_members(group_id);
create index if not exists idx_messages_group_created_at on messages(group_id, created_at);
create index if not exists idx_group_leaderboard_group_points on group_leaderboard(group_id, points desc);

alter table groups enable row level security;
alter table group_members enable row level security;
alter table messages enable row level security;
alter table group_leaderboard enable row level security;

create or replace function is_group_member(target_group_id uuid, target_user_id uuid default auth.uid())
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from group_members gm
    where gm.group_id = target_group_id
      and gm.user_id = target_user_id
  );
$$;

drop policy if exists "Users can read groups they belong to" on groups;
create policy "Users can read groups they belong to"
on groups for select
using (is_group_member(id) or created_by = auth.uid());

drop policy if exists "Users can create groups" on groups;
create policy "Users can create groups"
on groups for insert
with check (created_by = auth.uid());

drop policy if exists "Users can read memberships for their groups" on group_members;
create policy "Users can read memberships for their groups"
on group_members for select
using (is_group_member(group_id));

drop policy if exists "Users can join themselves to groups" on group_members;
create policy "Users can join themselves to groups"
on group_members for insert
with check (user_id = auth.uid());

drop policy if exists "Users can read messages from their groups" on messages;
create policy "Users can read messages from their groups"
on messages for select
using (is_group_member(group_id));

drop policy if exists "Users can send messages to their groups" on messages;
create policy "Users can send messages to their groups"
on messages for insert
with check (user_id = auth.uid() and is_group_member(group_id));

drop policy if exists "Users can read leaderboard for their groups" on group_leaderboard;
create policy "Users can read leaderboard for their groups"
on group_leaderboard for select
using (is_group_member(group_id));

drop policy if exists "Users can seed leaderboard for their groups" on group_leaderboard;
create policy "Users can seed leaderboard for their groups"
on group_leaderboard for insert
with check (user_id = auth.uid() and is_group_member(group_id));
