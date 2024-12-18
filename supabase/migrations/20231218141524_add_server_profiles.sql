create table if not exists server_profiles (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  server_id uuid references servers(id) on delete cascade not null,
  nickname text not null,
  pronouns text,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, server_id)
);
