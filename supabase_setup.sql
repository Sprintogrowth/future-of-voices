-- Run this in Supabase SQL Editor

-- Voices directory (public)
create table if not exists fov_voices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  cat text not null,
  label text,
  init text,
  type text not null default 'video',
  video_url text,
  message text,
  photo_url text,
  published_date text,
  created_at timestamptz default now()
);

-- Registration applications (from the public form)
create table if not exists fov_registrations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  cat text,
  social_handle text,
  bio text,
  type text,
  message text,
  video_url text,
  created_at timestamptz default now()
);

-- Storage bucket for photos and videos
insert into storage.buckets (id, name, public)
values ('fov-media', 'fov-media', true)
on conflict (id) do nothing;

-- RLS policies
alter table fov_voices enable row level security;
alter table fov_registrations enable row level security;

-- Anyone can read voices
create policy "public read voices" on fov_voices for select using (true);
-- Only logged-in admin can write voices
create policy "admin insert voices" on fov_voices for insert with check (auth.role() = 'authenticated');
create policy "admin update voices" on fov_voices for update using (auth.role() = 'authenticated');
create policy "admin delete voices" on fov_voices for delete using (auth.role() = 'authenticated');

-- Anyone can submit a registration
create policy "public insert registrations" on fov_registrations for insert with check (true);
-- Only admin can read registrations
create policy "admin read registrations" on fov_registrations for select using (auth.role() = 'authenticated');

-- Storage: anyone reads, only authenticated uploads
create policy "public read fov-media" on storage.objects for select using (bucket_id = 'fov-media');
create policy "admin upload fov-media" on storage.objects for insert with check (bucket_id = 'fov-media' and auth.role() = 'authenticated');
create policy "admin delete fov-media" on storage.objects for delete using (bucket_id = 'fov-media' and auth.role() = 'authenticated');
