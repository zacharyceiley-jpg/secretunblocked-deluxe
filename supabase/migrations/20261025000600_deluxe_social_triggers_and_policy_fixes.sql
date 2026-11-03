
drop policy if exists group_members_read_peers on public.deluxe_group_members;
create policy group_members_read_peers on public.deluxe_group_members for select to authenticated using(exists(select 1 from public.deluxe_group_members mine where mine.group_id=deluxe_group_members.group_id and mine.user_id=(select auth.uid())));
create or replace function public.deluxe_friend_request_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if new.status='pending' then
   insert into public.deluxe_notifications(user_id,title,body,kind) values(new.recipient_id,'Friend request','Someone sent you a friend request. Open Users to respond.','friend_request');
 end if; return new;
end; $$;
revoke all on function public.deluxe_friend_request_notify() from public, anon, authenticated;
drop trigger if exists deluxe_friend_request_notify_trigger on public.friend_requests;
create trigger deluxe_friend_request_notify_trigger after insert on public.friend_requests for each row execute function public.deluxe_friend_request_notify();
create or replace function public.deluxe_friendship_accept() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
 if new.status='accepted' and old.status is distinct from 'accepted' then
  insert into public.friendships(user_id,friend_id) values(new.sender_id,new.recipient_id) on conflict do nothing;
  insert into public.friendships(user_id,friend_id) values(new.recipient_id,new.sender_id) on conflict do nothing;
  insert into public.deluxe_notifications(user_id,title,body,kind) values(new.sender_id,'Friend request accepted','Your friend request was accepted.','friend_accepted');
 end if; return new;
end; $$;
revoke all on function public.deluxe_friendship_accept() from public, anon, authenticated;
drop trigger if exists deluxe_friendship_accept_trigger on public.friend_requests;
create trigger deluxe_friendship_accept_trigger after update of status on public.friend_requests for each row execute function public.deluxe_friendship_accept();
