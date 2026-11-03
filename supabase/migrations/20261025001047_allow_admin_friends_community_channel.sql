
create or replace function public.deluxe_can_access_admins_channel() returns boolean language sql stable security definer set search_path=public,pg_temp as $$
 select exists(select 1 from public.friendships f join public.user_roles ur on ur.user_id=f.friend_id where f.user_id=(select auth.uid()) and ur.role='admin');
$$;
revoke all on function public.deluxe_can_access_admins_channel() from public, anon;
grant execute on function public.deluxe_can_access_admins_channel() to authenticated;
drop policy if exists community_read_allowed on public.community_messages;
create policy community_read_allowed on public.community_messages for select to authenticated using (
 channel in ('general','bugs','news')
 or exists(select 1 from public.user_roles ur where ur.user_id=(select auth.uid()) and ur.role='admin')
 or (channel='admins' and public.deluxe_can_access_admins_channel())
);
