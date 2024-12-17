-- Drop existing policies if they exist
DO $$ 
BEGIN
    -- Users policies
    DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
    DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
    
    -- Servers policies
    DROP POLICY IF EXISTS "Server members can view servers" ON public.servers;
    DROP POLICY IF EXISTS "Server owners can update servers" ON public.servers;
    
    -- Server members policies
    DROP POLICY IF EXISTS "Server members can view other members" ON public.server_members;
    DROP POLICY IF EXISTS "Users can update their own member status" ON public.server_members;
    
    -- Channels policies
    DROP POLICY IF EXISTS "Server members can view channels" ON public.channels;
    
    -- Messages policies
    DROP POLICY IF EXISTS "Server members can view messages" ON public.messages;
    DROP POLICY IF EXISTS "Users can create messages" ON public.messages;
END $$;

-- Create or update users table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
        CREATE TABLE public.users (
            id uuid references auth.users on delete cascade primary key,
            username text not null unique,
            avatar_url text,
            created_at timestamp with time zone default timezone('utc'::text, now()) not null,
            updated_at timestamp with time zone default timezone('utc'::text, now()) not null
        );
    END IF;
END $$;

-- Create or update servers table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'servers') THEN
        CREATE TABLE public.servers (
            id uuid default gen_random_uuid() primary key,
            name text not null,
            icon_url text,
            owner_id uuid references public.users(id) on delete cascade not null,
            created_at timestamp with time zone default timezone('utc'::text, now()) not null,
            updated_at timestamp with time zone default timezone('utc'::text, now()) not null
        );
    END IF;
END $$;

-- Create or update server_members table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'server_members') THEN
        CREATE TABLE public.server_members (
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
    END IF;
END $$;

-- Create or update channels table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'channels') THEN
        CREATE TABLE public.channels (
            id uuid default gen_random_uuid() primary key,
            server_id uuid references public.servers(id) on delete cascade not null,
            name text not null,
            type text not null default 'text',
            created_at timestamp with time zone default timezone('utc'::text, now()) not null,
            updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
            unique(server_id, name)
        );
    END IF;
END $$;

-- Create or update messages table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
        CREATE TABLE public.messages (
            id uuid default gen_random_uuid() primary key,
            channel_id uuid references public.channels(id) on delete cascade not null,
            user_id uuid references public.users(id) on delete cascade not null,
            content text not null,
            created_at timestamp with time zone default timezone('utc'::text, now()) not null,
            updated_at timestamp with time zone default timezone('utc'::text, now()) not null
        );
    END IF;
END $$;

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Server members can view servers"
  ON public.servers FOR SELECT
  USING (exists (
    select 1 from public.server_members
    where server_members.server_id = servers.id
    and server_members.user_id = auth.uid()
  ));

CREATE POLICY "Server owners can update servers"
  ON public.servers FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Server members can view other members"
  ON public.server_members FOR SELECT
  USING (exists (
    select 1 from public.server_members as sm
    where sm.server_id = server_members.server_id
    and sm.user_id = auth.uid()
  ));

CREATE POLICY "Users can update their own member status"
  ON public.server_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Server members can view channels"
  ON public.channels FOR SELECT
  USING (exists (
    select 1 from public.server_members
    where server_members.server_id = channels.server_id
    and server_members.user_id = auth.uid()
  ));

CREATE POLICY "Server members can view messages"
  ON public.messages FOR SELECT
  USING (exists (
    select 1 from public.channels
    join public.server_members on server_members.server_id = channels.server_id
    where channels.id = messages.channel_id
    and server_members.user_id = auth.uid()
  ));

CREATE POLICY "Users can create messages"
  ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
begin
  insert into public.users (id, username, avatar_url)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
