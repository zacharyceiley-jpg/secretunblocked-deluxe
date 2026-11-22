create or replace function public.admin_gift_user_created_theme(
  p_target_user_id uuid,
  p_game_id uuid
)
returns table(username text, theme_name text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_theme public.game_theme_designs%rowtype;
  v_username text;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select * into v_theme
  from public.game_theme_designs
  where game_id = p_game_id;

  if not found then
    raise exception 'Creator theme not found';
  end if;

  select p.username into v_username
  from public.profiles p
  where p.id = p_target_user_id;

  if not found then
    raise exception 'Recipient not found';
  end if;

  if exists (
    select 1 from public.user_created_theme_ownership
    where user_id = p_target_user_id and game_id = p_game_id
  ) then
    raise exception 'That user already owns this theme';
  end if;

  insert into public.user_created_theme_ownership(user_id, game_id, acquired_via)
  values (p_target_user_id, p_game_id, 'gift');

  insert into public.game_theme_unlocks(user_id, game_id, fresh_seconds, unlocked_at, is_active)
  values (p_target_user_id, p_game_id, 60, now(), false)
  on conflict (user_id, game_id) do update
    set unlocked_at = coalesce(public.game_theme_unlocks.unlocked_at, now()),
        fresh_seconds = greatest(public.game_theme_unlocks.fresh_seconds, 60),
        updated_at = now();

  return query
  select v_username, v_theme.theme_name;
end;
$$;

revoke all on function public.admin_gift_user_created_theme(uuid, uuid) from public, anon;
grant execute on function public.admin_gift_user_created_theme(uuid, uuid) to authenticated;
