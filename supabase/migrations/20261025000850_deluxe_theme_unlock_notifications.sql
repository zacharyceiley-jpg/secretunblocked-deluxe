
create or replace function public.deluxe_theme_unlock_notify() returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
declare theme_name text;
begin
 if new.unlocked_themes is distinct from old.unlocked_themes then
  foreach theme_name in array coalesce(new.unlocked_themes,'{}'::text[]) loop
   if not (theme_name = any(coalesce(old.unlocked_themes,'{}'::text[]))) then
    insert into public.deluxe_notifications(user_id,title,body,kind) values(new.id,case when theme_name='sfoth' then 'SFOTH theme unlocked!' else initcap(theme_name)||' theme unlocked!' end,case when theme_name='sfoth' then 'Your SFOTH exclusive theme is now available in Settings.' else 'A new exclusive theme is now available in Settings.' end,'theme');
   end if;
  end loop;
 end if; return new;
end; $$;
revoke all on function public.deluxe_theme_unlock_notify() from public, anon, authenticated;
drop trigger if exists deluxe_theme_unlock_notify_trigger on public.profiles;
create trigger deluxe_theme_unlock_notify_trigger after update of unlocked_themes on public.profiles for each row execute function public.deluxe_theme_unlock_notify();
