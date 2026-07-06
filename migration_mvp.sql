-- FUTURE OF VOICES — MVP migration (T1 + T2 of the Master Developer Document)
-- Run in Supabase SQL Editor. Idempotent where possible.
-- When Sonia's own project (EU Frankfurt) is ready, run this same file there.

-- ============ T1: SUBMISSIONS TABLE (single source of truth) ============
create table if not exists submissions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null,
  email text not null,
  category text not null,
  social_handle text,
  bio text,
  photo_url text,
  video_url text,
  written_message text,
  status text not null default 'pending'
    check (status in ('pending','approved','published','rejected')),
  consent_accepted boolean not null default false,
  consent_accepted_at timestamptz,
  consent_terms_version text, -- 'v1.0-2026-07'
  newsletter_opt_in boolean not null default false,
  admin_notes text,
  published_at timestamptz
);

-- ============ T2: RLS ============
alter table submissions enable row level security;

drop policy if exists "public_can_insert" on submissions;
create policy "public_can_insert"
  on submissions for insert to anon with check (true);

drop policy if exists "admin_full_read" on submissions;
create policy "admin_full_read"
  on submissions for select to authenticated using (true);

drop policy if exists "admin_full_update" on submissions;
create policy "admin_full_update"
  on submissions for update to authenticated using (true);

drop policy if exists "admin_full_delete" on submissions;
create policy "admin_full_delete"
  on submissions for delete to authenticated using (true);

-- Public directory view: published only, NO emails, no consent data
create or replace view public_voices as
  select id, full_name, category, social_handle,
         photo_url, video_url, written_message, published_at
  from submissions where status = 'published';

-- View runs with owner rights (default): exposes ONLY published rows / safe columns to anon
grant select on public_voices to anon;
grant select on public_voices to authenticated;

-- ============ T2: STORAGE BUCKETS ============
insert into storage.buckets (id, name, public)
  values ('photos', 'photos', true)
  on conflict (id) do nothing;
insert into storage.buckets (id, name, public)
  values ('videos', 'videos', true)
  on conflict (id) do nothing;

drop policy if exists "public read photos" on storage.objects;
create policy "public read photos" on storage.objects
  for select using (bucket_id = 'photos');

drop policy if exists "public read videos" on storage.objects;
create policy "public read videos" on storage.objects
  for select using (bucket_id = 'videos');

-- Insert-only for anon (no update/delete), authenticated full manage
drop policy if exists "anon upload photos" on storage.objects;
create policy "anon upload photos" on storage.objects
  for insert to anon with check (bucket_id = 'photos');

drop policy if exists "anon upload videos" on storage.objects;
create policy "anon upload videos" on storage.objects
  for insert to anon with check (bucket_id = 'videos');

drop policy if exists "admin manage photos" on storage.objects;
create policy "admin manage photos" on storage.objects
  for all to authenticated using (bucket_id in ('photos','videos'))
  with check (bucket_id in ('photos','videos'));

drop policy if exists "admin delete media" on storage.objects;
create policy "admin delete media" on storage.objects
  for delete to authenticated using (bucket_id in ('photos','videos'));
