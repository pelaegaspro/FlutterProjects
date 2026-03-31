-- =============================================================
-- Colastica XI — Row Level Security Policies
-- Run this in the Supabase SQL Editor (or via supabase db push).
-- =============================================================

-- ---------------------------------------------------------------
-- Enable RLS on all tables
-- ---------------------------------------------------------------
alter table public.teams              enable row level security;
alter table public.contests           enable row level security;
alter table public.contest_entries    enable row level security;
alter table public.leaderboard        enable row level security;


-- ---------------------------------------------------------------
-- teams
--   • Users can only read, insert, and delete their own teams.
--   • No direct updates (create a new team instead).
-- ---------------------------------------------------------------
create policy "teams: owner can read"
  on public.teams for select
  using ( auth.uid() = user_id );

create policy "teams: owner can insert"
  on public.teams for insert
  with check ( auth.uid() = user_id );

create policy "teams: owner can delete"
  on public.teams for delete
  using ( auth.uid() = user_id );


-- ---------------------------------------------------------------
-- contests
--   • Anyone authenticated can read contests (browse lobby).
--   • Only service-role / admin can insert/update/delete contests
--     (managed from your backend or Supabase dashboard).
-- ---------------------------------------------------------------
create policy "contests: authenticated users can read"
  on public.contests for select
  using ( auth.role() = 'authenticated' );


-- ---------------------------------------------------------------
-- contest_entries
--   • Users can read their own entries.
--   • Users can join (insert) a contest for their own team.
--   • Users cannot modify or delete entries once submitted.
-- ---------------------------------------------------------------
create policy "contest_entries: owner can read"
  on public.contest_entries for select
  using ( auth.uid() = user_id );

create policy "contest_entries: owner can insert"
  on public.contest_entries for insert
  with check (
    auth.uid() = user_id
    -- Ensure the team being entered actually belongs to this user.
    and exists (
      select 1 from public.teams t
      where t.id = team_id
        and t.user_id = auth.uid()
    )
  );


-- ---------------------------------------------------------------
-- leaderboard
--   • All authenticated users can read the leaderboard.
--   • Only service-role can write leaderboard rows
--     (scores are computed server-side / via edge functions).
-- ---------------------------------------------------------------
create policy "leaderboard: authenticated users can read"
  on public.leaderboard for select
  using ( auth.role() = 'authenticated' );


-- ---------------------------------------------------------------
-- Verification queries — run after applying policies
-- ---------------------------------------------------------------
-- select tablename, policyname, cmd, qual
-- from pg_policies
-- where schemaname = 'public'
-- order by tablename, cmd;
