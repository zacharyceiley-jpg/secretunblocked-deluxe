
create or replace function public.deluxe_group_message_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare sender_name text; member record;
begin
 select username into sender_name from public.profiles where id=new.sender_id;
 for member in select user_id from public.deluxe_group_members where group_id=new.group_id and user_id<>new.sender_id loop
  insert into public.deluxe_notifications(user_id,title,body,kind) values(member.user_id,'New group message · '||coalesce((select name from public.deluxe_groups where id=new.group_id),'Group'),coalesce(sender_name,'A member')||': '||left(new.content,140),'group_message');
 end loop; return new;
end; $$;
revoke all on function public.deluxe_group_message_notify() from public, anon, authenticated;
drop trigger if exists deluxe_group_message_notify_trigger on public.deluxe_group_messages;
create trigger deluxe_group_message_notify_trigger after insert on public.deluxe_group_messages for each row execute function public.deluxe_group_message_notify();
