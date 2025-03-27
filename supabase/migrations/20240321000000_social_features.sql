-- Create profiles table
create table profiles (
    id uuid references auth.users on delete cascade primary key,
    username text unique not null,
    bio text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create comments table
create table comments (
    id uuid default gen_random_uuid() primary key,
    trip_id uuid references trips on delete cascade not null,
    user_id uuid references auth.users on delete cascade not null,
    content text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create likes table
create table likes (
    trip_id uuid references trips on delete cascade not null,
    user_id uuid references auth.users on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    primary key (trip_id, user_id)
);

-- Set up Row Level Security (RLS)
alter table profiles enable row level security;
alter table comments enable row level security;
alter table likes enable row level security;

-- Profiles policies
create policy "Public profiles are viewable by everyone"
    on profiles for select
    using (true);

create policy "Users can insert their own profile"
    on profiles for insert
    with check (auth.uid() = id);

create policy "Users can update own profile"
    on profiles for update
    using (auth.uid() = id);

-- Comments policies
create policy "Comments are viewable by everyone"
    on comments for select
    using (true);

create policy "Authenticated users can insert comments"
    on comments for insert
    with check (auth.role() = 'authenticated');

create policy "Users can update own comments"
    on comments for update
    using (auth.uid() = user_id);

create policy "Users can delete own comments"
    on comments for delete
    using (auth.uid() = user_id);

-- Likes policies
create policy "Likes are viewable by everyone"
    on likes for select
    using (true);

create policy "Authenticated users can insert likes"
    on likes for insert
    with check (auth.role() = 'authenticated');

create policy "Users can delete own likes"
    on likes for delete
    using (auth.uid() = user_id);

-- Create a trigger to create a profile after signup
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, username)
    values (new.id, new.raw_user_meta_data->>'username');
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user(); 