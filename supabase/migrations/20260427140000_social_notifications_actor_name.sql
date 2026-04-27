-- Adds actor display name for existing DBs that ran the first migration without this column.
-- Safe to run even if the column already exists.

alter table public.social_notifications
  add column if not exists actor_name text;

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
