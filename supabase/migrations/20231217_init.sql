-- Create users table
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  username text not null unique,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create servers table
create table public.servers (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  icon_url text,
  owner_id uuid references public.users(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create server_members table
create table public.server_members (
  id uuid default gen_random_uuid() primary key,
  server_id uuid references public.servers(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  role text not null default 'member',
  status text not null default 'offline',
  last_seen timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(server_id, user_id)
);

-- Create channels table
create table public.channels (
  id uuid default gen_random_uuid() primary key,
  server_id uuid references public.servers(id) on delete cascade not null,
  name text not null,
  type text not null default 'text',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(server_id, name)
);

-- Create messages table
create table public.messages (
  id uuid default gen_random_uuid() primary key,
  channel_id uuid references public.channels(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  content text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up Row Level Security (RLS)
alter table public.users enable row level security;
alter table public.servers enable row level security;
alter table public.server_members enable row level security;
alter table public.channels enable row level security;
alter table public.messages enable row level security;

-- Create policies
create policy "Users can view their own data"
  on public.users for select
  using (auth.uid() = id);

create policy "Users can update their own data"
  on public.users for update
  using (auth.uid() = id);

create policy "Server members can view servers"
  on public.servers for select
  using (exists (
    select 1 from public.server_members
    where server_members.server_id = servers.id
    and server_members.user_id = auth.uid()
  ));

create policy "Server owners can update servers"
  on public.servers for update
  using (owner_id = auth.uid());

create policy "Server members can view other members"
  on public.server_members for select
  using (exists (
    select 1 from public.server_members as sm
    where sm.server_id = server_members.server_id
    and sm.user_id = auth.uid()
  ));

create policy "Users can update their own member status"
  on public.server_members for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Server members can view channels"
  on public.channels for select
  using (exists (
    select 1 from public.server_members
    where server_members.server_id = channels.server_id
    and server_members.user_id = auth.uid()
  ));

create policy "Server members can view messages"
  on public.messages for select
  using (exists (
    select 1 from public.channels
    join public.server_members on server_members.server_id = channels.server_id
    where channels.id = messages.channel_id
    and server_members.user_id = auth.uid()
  ));

create policy "Users can create messages"
  on public.messages for insert
  with check (auth.uid() = user_id);

-- Create functions
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, username, avatar_url)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;

-- Create triggers
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
