-- User-saved daily motivations from Recovery Tips (optional, per-user).

create table if not exists public.saved_motivations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  motivation_text text not null,
  mood text,
  source_date date not null,
  created_at timestamptz not null default now()
);

create index if not exists saved_motivations_user_created_idx
  on public.saved_motivations (user_id, created_at desc);

create index if not exists saved_motivations_user_source_date_idx
  on public.saved_motivations (user_id, source_date desc);

alter table public.saved_motivations enable row level security;

create policy "saved_motivations_select_own"
  on public.saved_motivations
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "saved_motivations_insert_own"
  on public.saved_motivations
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "saved_motivations_delete_own"
  on public.saved_motivations
  for delete
  to authenticated
  using (auth.uid() = user_id);
