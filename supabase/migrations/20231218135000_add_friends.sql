-- Create friends table
create table friends (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    friend_id uuid references auth.users(id) not null,
    status text not null check (status in ('pending', 'accepted', 'blocked')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id, friend_id)
);

-- Add indexes
create index friends_user_id_idx on friends(user_id);
create index friends_friend_id_idx on friends(friend_id);
create index friends_status_idx on friends(status);

-- Add RLS policies
alter table friends enable row level security;

create policy "Users can view their own friends"
    on friends for select
    using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "Users can manage their own friends"
    on friends for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "Users can update their own friends"
    on friends for update
    using (auth.uid() = user_id or auth.uid() = friend_id);

create policy "Users can delete their own friends"
    on friends for delete
    using (auth.uid() = user_id);
