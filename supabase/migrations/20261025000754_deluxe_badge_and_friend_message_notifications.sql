
create or replace function public.deluxe_badge_award_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare badge_name text;
begin
 select name into badge_name from public.deluxe_badges where id=new.badge_id;
 insert into public.deluxe_notifications(user_id,title,body,kind) values(new.user_id,'Badge unlocked: '||coalesce(badge_name,'Game badge'),'You earned a game badge.','badge');
 return new;
end; $$;
revoke all on function public.deluxe_badge_award_notify() from public, anon, authenticated;
drop trigger if exists deluxe_badge_award_notify_trigger on public.user_badges;
create trigger deluxe_badge_award_notify_trigger after insert on public.user_badges for each row execute function public.deluxe_badge_award_notify();
create or replace function public.deluxe_friend_message_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare sender_name text;
begin
 select username into sender_name from public.profiles where id=new.sender_id;
 insert into public.deluxe_notifications(user_id,title,body,kind) values(new.recipient_id,'Message from '||coalesce(sender_name,'a friend'),left(new.content,180),'friend_message');
 return new;
end; $$;
revoke all on function public.deluxe_friend_message_notify() from public, anon, authenticated;
drop trigger if exists deluxe_friend_message_notify_trigger on public.friend_messages;
create trigger deluxe_friend_message_notify_trigger after insert on public.friend_messages for each row execute function public.deluxe_friend_message_notify();
