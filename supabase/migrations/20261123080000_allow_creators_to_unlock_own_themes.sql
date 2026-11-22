create policy "Creators unlock their own game themes"
on public.game_theme_unlocks
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and unlocked_at is not null
  and exists (
    select 1
    from public.game_theme_designs d
    where d.game_id = game_theme_unlocks.game_id
      and d.creator_id = (select auth.uid())
  )
);
