-- Create AI chat storage (run once in Supabase SQL Editor if chat_messages does not exist).

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null,
  content text not null,
  created_at timestamptz not null default now(),
  conversation_id text null
);

comment on table public.chat_messages is 'AI chat messages per user; conversation_id groups threads';

create index if not exists idx_chat_messages_user_conversation
  on public.chat_messages (user_id, conversation_id);

create index if not exists idx_chat_messages_user_created
  on public.chat_messages (user_id, created_at desc);

alter table public.chat_messages enable row level security;

-- Replace policies if you re-run: drop first avoids "already exists" errors.
drop policy if exists "chat_messages_select_own" on public.chat_messages;
drop policy if exists "chat_messages_insert_own" on public.chat_messages;
drop policy if exists "chat_messages_delete_own" on public.chat_messages;

create policy "chat_messages_select_own"
  on public.chat_messages for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "chat_messages_insert_own"
  on public.chat_messages for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "chat_messages_delete_own"
  on public.chat_messages for delete
  to authenticated
  using ((select auth.uid()) = user_id);
