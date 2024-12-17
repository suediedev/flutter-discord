-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.server_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
    EXECUTE 'DROP POLICY IF EXISTS "Users can view their own data" ON public.users';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update their own data" ON public.users';
    EXECUTE 'DROP POLICY IF EXISTS "Server members can view servers" ON public.servers';
    EXECUTE 'DROP POLICY IF EXISTS "Server owners can update servers" ON public.servers';
    EXECUTE 'DROP POLICY IF EXISTS "Server members can view other members" ON public.server_members';
    EXECUTE 'DROP POLICY IF EXISTS "Users can update their own member status" ON public.server_members';
    EXECUTE 'DROP POLICY IF EXISTS "Server members can view channels" ON public.channels';
    EXECUTE 'DROP POLICY IF EXISTS "Server members can view messages" ON public.messages';
    EXECUTE 'DROP POLICY IF EXISTS "Users can create messages" ON public.messages';
    EXECUTE 'DROP POLICY IF EXISTS "Users can create servers" ON public.servers';
    EXECUTE 'DROP POLICY IF EXISTS "Users can join servers" ON public.server_members';
EXCEPTION
    WHEN undefined_table THEN
        NULL;
END $$;

-- Create policies for users
CREATE POLICY "Users can view their own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Create policies for servers
CREATE POLICY "Users can view servers"
  ON public.servers FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Server owners can update servers"
  ON public.servers FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Users can create servers"
  ON public.servers FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- Create policies for server members
CREATE POLICY "Users can view server members"
  ON public.server_members FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can join servers"
  ON public.server_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own member status"
  ON public.server_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create policies for channels
CREATE POLICY "Users can view channels"
  ON public.channels FOR SELECT
  TO authenticated
  USING (true);

-- Create policies for messages
CREATE POLICY "Users can view messages"
  ON public.messages FOR SELECT
  TO authenticated
  USING (true);

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
