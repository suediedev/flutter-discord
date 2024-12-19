-- Create tables
CREATE TABLE public.channels (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  server_id uuid NULL,
  name text NOT NULL,
  position integer NULL DEFAULT 0,
  created_by uuid NULL,
  created_at timestamp with time zone NULL DEFAULT timezone('utc', now()),
  CONSTRAINT channels_pkey PRIMARY KEY (id),
  CONSTRAINT channels_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT channels_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

CREATE TABLE public.friends (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  status text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT friends_pkey PRIMARY KEY (id),
  CONSTRAINT friends_user_id_friend_id_key UNIQUE (user_id, friend_id),
  CONSTRAINT friends_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES auth.users(id),
  CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT friends_status_check CHECK ((status = ANY (ARRAY['pending', 'accepted', 'blocked'])))
);

CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  channel_id uuid NULL,
  user_id uuid NULL,
  content text NOT NULL,
  created_at timestamp with time zone NULL DEFAULT timezone('utc', now()),
  user_display_name text NULL,
  reply_to_id uuid NULL,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE,
  CONSTRAINT messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES messages(id),
  CONSTRAINT messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  recipient_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  server_id uuid NULL,
  channel_id uuid NULL,
  message_id uuid NULL,
  type text NOT NULL,
  content text NOT NULL,
  read boolean NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_message_id_fkey FOREIGN KEY (message_id) REFERENCES messages(id),
  CONSTRAINT notifications_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES channels(id),
  CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id),
  CONSTRAINT notifications_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id),
  CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES auth.users(id),
  CONSTRAINT notifications_type_check CHECK ((type = ANY (ARRAY['mention', 'reply'])))
);

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL,
  avatar_url text NULL,
  updated_at timestamp with time zone NULL DEFAULT timezone('utc', now()),
  status text NULL DEFAULT 'offline',
  last_seen timestamp with time zone NULL DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_username_key UNIQUE (username),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

CREATE TABLE public.server_invites (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  server_id uuid NULL,
  code text NOT NULL,
  created_by uuid NULL,
  created_at timestamp with time zone NULL DEFAULT now(),
  expires_at timestamp with time zone NULL,
  max_uses integer NULL,
  uses integer NULL DEFAULT 0,
  CONSTRAINT server_invites_pkey PRIMARY KEY (id),
  CONSTRAINT server_invites_code_key UNIQUE (code),
  CONSTRAINT server_invites_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id),
  CONSTRAINT server_invites_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
  CONSTRAINT valid_max_uses CHECK (((max_uses IS NULL) OR (max_uses > 0)))
);

CREATE TABLE public.server_members (
  server_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'member',
  joined_at timestamp with time zone NULL DEFAULT timezone('utc', now()),
  status text NULL DEFAULT 'offline',
  last_seen timestamp with time zone NULL DEFAULT now(),
  CONSTRAINT server_members_pkey PRIMARY KEY (server_id, user_id),
  CONSTRAINT server_members_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
  CONSTRAINT server_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE public.server_profiles (
  id uuid NOT NULL DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL,
  server_id uuid NOT NULL,
  nickname text NOT NULL,
  pronouns text NULL,
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT server_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT server_profiles_user_id_server_id_key UNIQUE (user_id, server_id),
  CONSTRAINT server_profiles_server_id_fkey FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
  CONSTRAINT server_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE TABLE public.servers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  icon_url text NULL,
  owner_id uuid NOT NULL,
  created_at timestamp with time zone NULL DEFAULT timezone('utc', now()),
  CONSTRAINT servers_pkey PRIMARY KEY (id),
  CONSTRAINT servers_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES auth.users(id)
);

CREATE TABLE public.users (
  id uuid NOT NULL,
  username text NOT NULL,
  avatar_url text NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_username_key UNIQUE (username),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Insert data into tables
-- You will need to manually create INSERT statements for each table based on your data.
