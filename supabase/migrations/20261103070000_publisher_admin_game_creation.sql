-- Publisher is admin-gift only. Only Publisher and Admin accounts may submit games.
-- Existing user_role_ownership rows are preserved.

create or replace function public.has_publisher_role()
returns boolean
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select auth.uid() is not null
     and exists (
       select 1
       from public.user_role_ownership
       where user_id = (select auth.uid())
         and role = 'publisher'
     );
$$;

revoke all on function public.has_publisher_role() from public, anon;
grant execute on function public.has_publisher_role() to authenticated;

drop policy if exists games_insert_self on public.games;
drop policy if exists games_insert_publisher_admin on public.games;
create policy games_insert_publisher_admin
on public.games
for insert
to authenticated
with check (
  creator_id = (select auth.uid())
  and not public.is_user_banned()
  and (public.is_admin() or public.has_publisher_role())
);

drop policy if exists user_role_ownership_admin_gift_publisher on public.user_role_ownership;
create policy user_role_ownership_admin_gift_publisher
on public.user_role_ownership
for insert
to authenticated
with check (public.is_admin() and role = 'publisher');

create or replace function public.delubux_buy_role(p_role text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  uid uuid := auth.uid();
  existing_base_role text;
  new_balance bigint;
  owned_roles text[];
  best_role text;
  role_cost bigint := 30;
begin
  if uid is null then raise exception 'Sign in to purchase a role.'; end if;
  if p_role <> 'bugtester' then raise exception 'Publisher is not for sale. An Admin must gift that role to you.'; end if;

  select role into existing_base_role from public.user_roles where user_id = uid;
  if existing_base_role = 'admin' then raise exception 'Admin accounts cannot purchase marketplace roles.'; end if;
  if exists(select 1 from public.user_role_ownership where user_id=uid and role=p_role) then
    raise exception 'You already own this role.';
  end if;

  update public.delubux_wallets
     set balance = balance - role_cost, updated_at = now()
   where user_id = uid and balance >= role_cost
   returning balance into new_balance;
  if new_balance is null then raise exception 'Not enough Delubux. You need %.', role_cost; end if;

  insert into public.user_role_ownership(user_id,role) values(uid,p_role);

  insert into public.delubux_transactions(user_id,amount,reason)
  values(uid,-role_cost,'Purchased Bugtester role');

  select coalesce(array_agg(role order by role),array[]::text[]) into owned_roles
  from public.user_role_ownership where user_id=uid;
  best_role := case
    when existing_base_role='admin' then 'admin'
    when 'publisher'=any(owned_roles) then 'publisher'
    when 'bugtester'=any(owned_roles) then 'bugtester'
    else 'user'
  end;

  return jsonb_build_object('ok',true,'role',p_role,'roles',to_jsonb(owned_roles),'best_role',best_role,'cost',role_cost,'balance',new_balance);
end;
$function$;
