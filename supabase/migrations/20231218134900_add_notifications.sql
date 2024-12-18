-- Create notifications table
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
create index notifications_recipient_id_idx on notifications(recipient_id);
create index notifications_created_at_idx on notifications(created_at);
create index notifications_read_idx on notifications(read);

-- Add RLS policies
alter table notifications enable row level security;

create policy "Users can view their own notifications"
    on notifications for select
    using (auth.uid() = recipient_id);

create policy "System can insert notifications"
    on notifications for insert
    to authenticated
    with check (true);

-- Function to create notification on mention
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

-- Trigger for mentions
create trigger on_mention_notification
    after insert on messages
    for each row
    execute function handle_mention_notification();

-- Function to create notification on reply
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

-- Trigger for replies
create trigger on_reply_notification
    after insert on messages
    for each row
    execute function handle_reply_notification();
