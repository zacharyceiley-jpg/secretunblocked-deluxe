-- Keep the newest 100 messages in each one-to-one friend conversation.
-- Both directions (A -> B and B -> A) belong to the same conversation.
create or replace function public.deluxe_trim_friend_message_history()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  pair_key text;
begin
  pair_key := least(new.sender_id::text, new.recipient_id::text)
              || ':' ||
              greatest(new.sender_id::text, new.recipient_id::text);

  -- Serialize sends in the same conversation so concurrent inserts cannot
  -- leave more than 100 rows behind.
  perform pg_advisory_xact_lock(hashtextextended(pair_key, 0));

  delete from public.friend_messages
  where id in (
    select id
    from public.friend_messages
    where (sender_id = new.sender_id and recipient_id = new.recipient_id)
       or (sender_id = new.recipient_id and recipient_id = new.sender_id)
    order by created_at desc, id desc
    offset 100
  );

  return new;
end;
$$;

drop trigger if exists deluxe_trim_friend_message_history_trigger
  on public.friend_messages;

create trigger deluxe_trim_friend_message_history_trigger
after insert on public.friend_messages
for each row
execute function public.deluxe_trim_friend_message_history();

revoke all on function public.deluxe_trim_friend_message_history()
  from public, anon, authenticated;
