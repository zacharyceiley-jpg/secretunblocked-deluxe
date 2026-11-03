
alter table public.friend_requests drop constraint if exists friend_requests_sender_id_fkey;
alter table public.friend_requests drop constraint if exists friend_requests_recipient_id_fkey;
alter table public.friend_requests add constraint friend_requests_sender_id_fkey foreign key(sender_id) references public.profiles(id) on delete cascade;
alter table public.friend_requests add constraint friend_requests_recipient_id_fkey foreign key(recipient_id) references public.profiles(id) on delete cascade;
alter table public.friendships drop constraint if exists friendships_user_id_fkey;
alter table public.friendships drop constraint if exists friendships_friend_id_fkey;
alter table public.friendships add constraint friendships_user_id_fkey foreign key(user_id) references public.profiles(id) on delete cascade;
alter table public.friendships add constraint friendships_friend_id_fkey foreign key(friend_id) references public.profiles(id) on delete cascade;
alter table public.friend_messages drop constraint if exists friend_messages_sender_id_fkey;
alter table public.friend_messages drop constraint if exists friend_messages_recipient_id_fkey;
alter table public.friend_messages add constraint friend_messages_sender_id_fkey foreign key(sender_id) references public.profiles(id) on delete cascade;
alter table public.friend_messages add constraint friend_messages_recipient_id_fkey foreign key(recipient_id) references public.profiles(id) on delete cascade;
alter table public.community_messages drop constraint if exists community_messages_sender_id_fkey;
alter table public.community_messages add constraint community_messages_sender_id_fkey foreign key(sender_id) references public.profiles(id) on delete cascade;
alter table public.deluxe_group_messages drop constraint if exists deluxe_group_messages_sender_id_fkey;
alter table public.deluxe_group_messages add constraint deluxe_group_messages_sender_id_fkey foreign key(sender_id) references public.profiles(id) on delete cascade;
