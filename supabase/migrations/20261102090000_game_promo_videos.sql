-- Store up to five YouTube promo video IDs per game.
alter table public.games
  add column if not exists promo_videos jsonb not null default '[]'::jsonb;

alter table public.games
  alter column promo_videos set default '[]'::jsonb;

update public.games
set promo_videos = '[]'::jsonb
where promo_videos is null;

alter table public.games
  alter column promo_videos set not null;

alter table public.games
  drop constraint if exists games_promo_videos_array_check;

alter table public.games
  add constraint games_promo_videos_array_check
  check (jsonb_typeof(promo_videos) = 'array' and jsonb_array_length(promo_videos) <= 5);
