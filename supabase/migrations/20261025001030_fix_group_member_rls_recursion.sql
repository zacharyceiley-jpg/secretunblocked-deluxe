
drop policy if exists group_members_read_peers on public.deluxe_group_members;
create policy group_members_read_own on public.deluxe_group_members for select to authenticated using(user_id=(select auth.uid()));
