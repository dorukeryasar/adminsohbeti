-- Doruk TV Sohbeti: Supabase SQL Editor'a yapıştırıp Run'a bas.
create table if not exists public.chat_users (
  id uuid primary key default gen_random_uuid(),
  username text not null,
  username_key text generated always as (lower(trim(username))) stored,
  created_at timestamptz not null default now()
);
create unique index if not exists chat_users_username_key_idx on public.chat_users(username_key);

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  username text not null,
  message text not null check (char_length(message) between 1 and 1000),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists chat_messages_created_at_idx on public.chat_messages(created_at desc);

alter table public.chat_users enable row level security;
alter table public.chat_messages enable row level security;

drop policy if exists "chat users read" on public.chat_users;
create policy "chat users read" on public.chat_users for select to anon using (true);

drop policy if exists "chat users insert" on public.chat_users;
create policy "chat users insert" on public.chat_users for insert to anon
with check (trim(username) <> '' and lower(trim(username)) <> 'admin');

drop policy if exists "chat messages read" on public.chat_messages;
create policy "chat messages read" on public.chat_messages for select to anon using (true);

drop policy if exists "chat messages insert" on public.chat_messages;
create policy "chat messages insert" on public.chat_messages for insert to anon
with check (trim(username) <> '' and lower(trim(username)) <> 'admin' and is_admin = false);

grant usage on schema public to anon;
grant select, insert on public.chat_users to anon;
grant select, insert on public.chat_messages to anon;
grant usage, select on all sequences in schema public to anon;

do $$
begin
  alter publication supabase_realtime add table public.chat_messages;
exception when duplicate_object then null;
end $$;
