
drop policy if exists user_badges_award_self on public.user_badges;
create policy user_badges_award_self on public.user_badges for insert to authenticated with check (
 user_id=(select auth.uid())
 and exists(select 1 from public.deluxe_badges b join public.game_playtime p on p.game_id=b.game_id and p.user_id=(select auth.uid()) where b.id=badge_id and b.condition_type='time_played' and p.seconds>=b.requirement_seconds)
);
