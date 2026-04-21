-- Run this in the Supabase SQL editor (or via CLI) so each chat thread is stored separately.
alter table public.chat_messages
  add column if not exists conversation_id text;

create index if not exists idx_chat_messages_user_conversation
  on public.chat_messages (user_id, conversation_id);

comment on column public.chat_messages.conversation_id is
  'UUID string per conversation; null = legacy rows before multi-chat support';
