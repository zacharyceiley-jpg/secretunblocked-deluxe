alter table public.profiles
  add column if not exists profile_theme_game_id uuid;
