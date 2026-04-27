-- In-app + Realtime: notify post authors when someone else likes or replies.
-- Requires existing public.emotion_posts, public.emotion_likes, public.emotion_replies.

create table if not exists public.social_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users (id) on delete cascade,
  actor_id uuid references auth.users (id) on delete set null,
  type text not null check (type in ('like', 'reply')),
  post_id uuid not null,
  preview_text text,
  actor_name text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists social_notifications_recipient_created_idx
  on public.social_notifications (recipient_id, created_at desc);

alter table public.social_notifications enable row level security;

create policy "social_notifications_select_own"
  on public.social_notifications
  for select
  to authenticated
  using (auth.uid() = recipient_id);

create policy "social_notifications_update_own"
  on public.social_notifications
  for update
  to authenticated
  using (auth.uid() = recipient_id)
  with check (auth.uid() = recipient_id);

-- Enable Realtime for this table in Dashboard (Database → Publications) if inserts are not received:
--   alter publication supabase_realtime add table public.social_notifications;

-- Triggers: only notify the post author; skip self-likes and self-replies
create or replace function public.tg_emotion_like_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  author_id uuid;
  actor_label text;
begin
  select user_id into author_id
  from public.emotion_posts
  where id = new.post_id;

  if author_id is null or author_id = new.user_id then
    return new;
  end if;

  select coalesce(
    nullif(trim(u.raw_user_meta_data->>'full_name'), ''),
    nullif(trim(u.raw_user_meta_data->>'name'), ''),
    split_part(u.email, '@', 1),
    'Member'
  ) into actor_label
  from auth.users u
  where u.id = new.user_id;

  insert into public.social_notifications (recipient_id, actor_id, type, post_id, preview_text, actor_name)
  values (author_id, new.user_id, 'like', new.post_id, null, coalesce(nullif(actor_label, ''), 'Member'));

  return new;
end;
$$;

drop trigger if exists trg_emotion_like_notify on public.emotion_likes;
create trigger trg_emotion_like_notify
  after insert on public.emotion_likes
  for each row
  execute procedure public.tg_emotion_like_notify();

create or replace function public.tg_emotion_reply_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  author_id uuid;
  preview text;
  actor_label text;
begin
  select user_id into author_id
  from public.emotion_posts
  where id = new.post_id;

  if author_id is null or author_id = new.user_id then
    return new;
  end if;

  preview := left(coalesce(new.text, ''), 200);

  select coalesce(
    nullif(trim(u.raw_user_meta_data->>'full_name'), ''),
    nullif(trim(u.raw_user_meta_data->>'name'), ''),
    split_part(u.email, '@', 1),
    'Member'
  ) into actor_label
  from auth.users u
  where u.id = new.user_id;

  insert into public.social_notifications (recipient_id, actor_id, type, post_id, preview_text, actor_name)
  values (author_id, new.user_id, 'reply', new.post_id, preview, coalesce(nullif(actor_label, ''), 'Member'));

  return new;
end;
$$;

drop trigger if exists trg_emotion_reply_notify on public.emotion_replies;
create trigger trg_emotion_reply_notify
  after insert on public.emotion_replies
  for each row
  execute procedure public.tg_emotion_reply_notify();
