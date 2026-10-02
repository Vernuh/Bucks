# BUCKS

Student finance manager built with Flutter. Auth and data live in Supabase.

## Architecture

    Screen -> AppStateProvider -> SupabaseService -> Supabase (Auth + Postgres + RLS)

AppStateProvider is the in-memory state; Supabase is the only persistent store.
The signed-in user's `auth.users.id` owns every row. Row Level Security
(`supabase/schema.sql`) stops one user from reading another user's data.

## Setup

1. Create a Supabase project.
2. In the dashboard open **SQL Editor**, paste `supabase/schema.sql`, and run it.
3. Copy `.env.example` to `.env` and fill in your project URL and **public**
   (anon / publishable) key from Project Settings > API.
4. Run:

       flutter pub get
       flutter run -d chrome --dart-define-from-file=.env

`.env` is git-ignored. Never put the service-role key, database password or
AI keys in this app.

## Tests

    flutter analyze
    flutter test
