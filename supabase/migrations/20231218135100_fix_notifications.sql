-- Drop existing triggers if they exist
drop trigger if exists on_mention_notification on messages;
drop trigger if exists on_reply_notification on messages;

-- Drop existing functions
drop function if exists handle_mention_notification();
drop function if exists handle_reply_notification();

-- Drop existing notifications table
drop table if exists notifications;

-- Recreate notifications table
create table notifications (
    id uuid default uuid_generate_v4() primary key,
    recipient_id uuid references auth.users(id) not null,
    sender_id uuid references auth.users(id) not null,
    server_id uuid references servers(id),
    channel_id uuid references channels(id),
    message_id uuid references messages(id),
    type text not null check (type in ('mention', 'reply')),
    content text not null,
    read boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add indexes for better query performance
create index if not exists notifications_recipient_id_idx on notifications(recipient_id);
create index if not exists notifications_created_at_idx on notifications(created_at);
create index if not exists notifications_read_idx on notifications(read);

-- Add RLS policies
alter table notifications enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Users can view their own notifications" on notifications;
drop policy if exists "System can insert notifications" on notifications;

-- Recreate policies
create policy "Users can view their own notifications"
    on notifications for select
    using (auth.uid() = recipient_id);

create policy "System can insert notifications"
    on notifications for insert
    to authenticated
    with check (true);

-- Create improved mention notification function
create or replace function handle_mention_notification()
returns trigger as $$
declare
    mentioned_username text;
    mentioned_user_id uuid;
begin
    -- Extract usernames mentioned in the message (anything after @)
    for mentioned_username in
        select unnest(regexp_matches(new.content, '@([^\s]+)', 'g'))
    loop
        -- Find the user ID for the mentioned username
        select id into mentioned_user_id
        from profiles
        where username ilike mentioned_username;

        if mentioned_user_id is not null and mentioned_user_id != new.user_id then
            -- Create notification for the mention
            insert into notifications (
                recipient_id,
                sender_id,
                server_id,
                channel_id,
                message_id,
                type,
                content
            ) values (
                mentioned_user_id,
                new.user_id,
                new.server_id,
                new.channel_id,
                new.id,
                'mention',
                new.content
            );
        end if;
    end loop;
    return new;
end;
$$ language plpgsql security definer;

-- Create reply notification function
create or replace function handle_reply_notification()
returns trigger as $$
begin
    if new.reply_to_id is not null then
        insert into notifications (
            recipient_id,
            sender_id,
            server_id,
            channel_id,
            message_id,
            type,
            content
        )
        select 
            m.user_id,
            new.user_id,
            new.server_id,
            new.channel_id,
            new.id,
            'reply',
            new.content
        from messages m
        where m.id = new.reply_to_id
        and m.user_id != new.user_id;
    end if;
    return new;
end;
$$ language plpgsql security definer;

-- Create triggers
create trigger on_mention_notification
    after insert on messages
    for each row
    execute function handle_mention_notification();

create trigger on_reply_notification
    after insert on messages
    for each row
    execute function handle_reply_notification();

-- Create friends table if it doesn't exist
create table if not exists friends (
    id uuid default uuid_generate_v4() primary key,
    user_id uuid references auth.users(id) not null,
    friend_id uuid references auth.users(id) not null,
    status text not null check (status in ('pending', 'accepted', 'blocked')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(user_id, friend_id)
);

-- Add indexes for friends table
create index if not exists friends_user_id_idx on friends(user_id);
create index if not exists friends_friend_id_idx on friends(friend_id);
create index if not exists friends_status_idx on friends(status);

-- Enable RLS on friends table
alter table friends enable row level security;

-- Drop existing friend policies if they exist
drop policy if exists "Users can view their own friends" on friends;
drop policy if exists "Users can manage their own friends" on friends;
drop policy if exists "Users can update their own friends" on friends;
drop policy if exists "Users can delete their own friends" on friends;

-- Recreate friend policies
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
