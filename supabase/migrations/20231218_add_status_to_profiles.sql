-- Add status and last_seen columns to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'offline',
ADD COLUMN IF NOT EXISTS last_seen timestamp with time zone DEFAULT now();

-- Add status and last_seen columns to server_members table
ALTER TABLE server_members
ADD COLUMN IF NOT EXISTS status text DEFAULT 'offline',
ADD COLUMN IF NOT EXISTS last_seen timestamp with time zone DEFAULT now();

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_server_members_status ON server_members(status);
CREATE INDEX IF NOT EXISTS idx_server_members_last_seen ON server_members(last_seen);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Update RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to view all profiles
CREATE POLICY "Public profiles are viewable by everyone"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);
