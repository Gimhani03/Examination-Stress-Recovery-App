-- Denormalized avatar fields so feed/replies can show preset or legacy photo URLs
-- without reading other users' auth metadata. Populated on insert from the author.
-- Anonymous posts should store NULL here (handled in app).

alter table public.emotion_posts
  add column if not exists author_avatar_preset_id text,
  add column if not exists author_avatar_url text;

alter table public.emotion_replies
  add column if not exists author_avatar_preset_id text,
  add column if not exists author_avatar_url text;
