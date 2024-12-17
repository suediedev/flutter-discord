-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS public.users (
    id uuid references auth.users on delete cascade primary key,
    username text not null unique,
    avatar_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE IF NOT EXISTS public.servers (
    id uuid default gen_random_uuid() primary key,
    name text not null,
    icon_url text,
    owner_id uuid references public.users(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

CREATE TABLE IF NOT EXISTS public.server_members (
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

CREATE TABLE IF NOT EXISTS public.channels (
    id uuid default gen_random_uuid() primary key,
    server_id uuid references public.servers(id) on delete cascade not null,
    name text not null,
    type text not null default 'text',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(server_id, name)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id uuid default gen_random_uuid() primary key,
    channel_id uuid references public.channels(id) on delete cascade not null,
    user_id uuid references public.users(id) on delete cascade not null,
    content text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);
