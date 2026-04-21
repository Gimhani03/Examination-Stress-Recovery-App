-- Create user_challenges table for tracking challenges per user
create table if not exists public.user_challenges (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  icon text not null,
  challenge_date date not null,
  completed boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create index for faster queries
create index if not exists idx_user_challenges_user_id 
  on public.user_challenges(user_id);

create index if not exists idx_user_challenges_user_date 
  on public.user_challenges(user_id, challenge_date);

-- Enable RLS
alter table public.user_challenges enable row level security;

-- RLS Policy: Users can only view their own challenges
create policy "Users can view their own challenges" on public.user_challenges
  for select using (auth.uid() = user_id);

-- RLS Policy: Users can insert their own challenges
create policy "Users can insert their own challenges" on public.user_challenges
  for insert with check (auth.uid() = user_id);

-- RLS Policy: Users can update their own challenges
create policy "Users can update their own challenges" on public.user_challenges
  for update using (auth.uid() = user_id);

-- RLS Policy: Users can delete their own challenges
create policy "Users can delete their own challenges" on public.user_challenges
  for delete using (auth.uid() = user_id);
