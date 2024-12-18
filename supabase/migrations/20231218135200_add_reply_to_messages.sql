-- Add reply_to_id column to messages table
alter table messages 
add column if not exists reply_to_id uuid references messages(id);

-- Add index for better performance on replies
create index if not exists messages_reply_to_id_idx on messages(reply_to_id);

-- Update messages table schema version
comment on table messages is 'Messages table with reply support - v2';
