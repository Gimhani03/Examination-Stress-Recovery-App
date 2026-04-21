-- Public bucket for profile photos (see ProfileAvatarService, bucket "avatars").
-- Apply: Supabase Dashboard → SQL Editor → Run, or `supabase db push` from this repo.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif']::text[]
)
on conflict (id) do update set
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Ensure existing bucket is public (fixes uploads if bucket was created private).
update storage.buckets set public = true where id = 'avatars';

drop policy if exists "avatars_public_read" on storage.objects;
drop policy if exists "avatars_authenticated_insert" on storage.objects;
drop policy if exists "avatars_authenticated_update" on storage.objects;
drop policy if exists "avatars_authenticated_delete" on storage.objects;

-- Anyone can read objects (required for getPublicUrl / Image.network).
create policy "avatars_public_read"
  on storage.objects
  for select
  using (bucket_id = 'avatars');

-- Users may only create files under their auth UUID folder: "{uid}/profile.ext"
create policy "avatars_authenticated_insert"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = (select auth.uid()::text)
  );

create policy "avatars_authenticated_update"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = (select auth.uid()::text)
  );

create policy "avatars_authenticated_delete"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = (select auth.uid()::text)
  );
