-- Authors must be allowed to UPDATE their own rows so profile-avatar sync can refresh
-- author_avatar_preset_id / author_avatar_url on old posts & replies (client-side sync).

drop policy if exists "emotion_posts_authenticated_update_own" on public.emotion_posts;
create policy "emotion_posts_authenticated_update_own"
  on public.emotion_posts
  for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

drop policy if exists "emotion_replies_authenticated_update_own" on public.emotion_replies;
create policy "emotion_replies_authenticated_update_own"
  on public.emotion_replies
  for update
  to authenticated
  using ( (select auth.uid()) = user_id )
  with check ( (select auth.uid()) = user_id );

-- If `user_id` is **text** storing UUIDs (not type uuid), recreate policies with:
--   using ( (select auth.uid())::text = user_id )
--   with check ( (select auth.uid())::text = user_id );

-- Legacy rows: NULL treated as non-anonymous for filtering (anonymous must be explicitly true).
-- Safe if anonymous posts always set is_anonymous = true; adjust if your data model differs.
update public.emotion_posts
set is_anonymous = false
where is_anonymous is null;
