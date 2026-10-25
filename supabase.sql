-- Supabase SQL Editor에서 실행. Authentication > Providers에서 Anonymous Sign-ins를 활성화하세요.
create extension if not exists pgcrypto;
create table if not exists public.rooms (
 id uuid primary key default gen_random_uuid(), visitor_id uuid not null references auth.users(id) on delete cascade,
 nickname text not null check (char_length(nickname) between 1 and 20), affection int not null default 5 check (affection between 0 and 100),
 ended boolean not null default false, ended_at timestamptz, created_at timestamptz not null default now(),
 last_message_at timestamptz, last_message_preview text, admin_last_read_at timestamptz, unread_count int not null default 0 check (unread_count >= 0)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(), room_id uuid not null references public.rooms(id) on delete cascade,
 sender text not null check (sender in ('visitor','admin')), sender_name text not null, content text not null default '', image_url text,
 created_at timestamptz not null default now(), constraint message_has_content check (length(trim(content))>0 or image_url is not null)
);
create index if not exists rooms_last_message_idx on public.rooms(last_message_at desc nulls last);
create index if not exists messages_room_created_idx on public.messages(room_id,created_at);
alter table public.rooms enable row level security;
alter table public.messages enable row level security;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select coalesce((auth.jwt()->'app_metadata'->>'role')='admin',false) $$;
create policy "visitor reads own room and admins read all" on public.rooms for select to authenticated using (visitor_id=auth.uid() or public.is_admin());
create policy "visitors create own room" on public.rooms for insert to authenticated with check (visitor_id=auth.uid() and affection=5 and ended=false and not public.is_admin());
create policy "admins update rooms" on public.rooms for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "visitors read own room messages and admins read all" on public.messages for select to authenticated using (public.is_admin() or exists(select 1 from public.rooms r where r.id=room_id and r.visitor_id=auth.uid()));
create policy "visitor sends own room text" on public.messages for insert to authenticated with check (
 sender='visitor' and sender_name=(select r.nickname from public.rooms r where r.id=room_id and r.visitor_id=auth.uid() and r.ended=false)
 and image_url is null and length(trim(content))>0
);
create policy "admins send messages" on public.messages for insert to authenticated with check (public.is_admin() and sender='admin' and sender_name='이동혁' and exists(select 1 from public.rooms r where r.id=room_id and r.ended=false));
-- Trigger ensures clients cannot forge room preview / ordering by sending arbitrary room updates.
create or replace function public.on_message_insert() returns trigger language plpgsql security definer set search_path=public as $$ begin
 update public.rooms set last_message_at=new.created_at, last_message_preview=case when new.image_url is not null and new.content='' then '사진' else left(new.content,120) end, unread_count=case when new.sender='visitor' then unread_count+1 else unread_count end where id=new.room_id;
 return new; end $$;
drop trigger if exists messages_after_insert on public.messages;
create trigger messages_after_insert after insert on public.messages for each row execute function public.on_message_insert();
-- Storage bucket: public image URLs are used by the chat UI; only admins can upload.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('chat-images','chat-images',true,10485760,array['image/jpeg','image/png','image/webp','image/gif']) on conflict(id) do nothing;
create policy "admins upload chat images" on storage.objects for insert to authenticated with check (bucket_id='chat-images' and public.is_admin());
create policy "chat images are readable" on storage.objects for select to public using (bucket_id='chat-images');
