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

## Gemini AI Setup

Buck's Chat and Buck's Insights use Gemini through a Supabase Edge Function:

    ChatScreen -> AiService -> Edge Function `bucks-ai` -> Gemini API

The Gemini API key lives **only** as a Supabase Edge Function secret. The
Flutter app never receives it and never calls Gemini directly.

1. Create a Gemini API key in [Google AI Studio](https://aistudio.google.com/app/apikey).
2. **Do not** put it in Flutter, `.env`, `.env.example`, assets or Git.
3. Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then link your project and store the key as a secret:

       supabase login
       supabase link --project-ref YOUR_PROJECT_REF
       supabase secrets set GEMINI_API_KEY=your_gemini_api_key

   (Optional) pick another model: `supabase secrets set GEMINI_MODEL=gemini-3.5-flash`
4. Deploy the function. The function verifies the user's login itself, so deploy
   with gateway JWT verification off (this works with both legacy and new JWT signing keys):

       supabase functions deploy bucks-ai --no-verify-jwt

5. Run the app as usual:

       flutter run -d chrome --dart-define-from-file=.env

What the function does: it checks the caller is a signed-in user, reads **that
user's own** transactions, budgets, goals and stats with their token (so Row
Level Security applies), sends Gemini only a compact summary (no email, notes
or ids), and returns `{ "reply": "..." }`. It limits each user to 20 questions
per 10 minutes.

Keep in mind:
- `.env` is private and git-ignored. `.env.example` is safe to commit.
- `GEMINI_API_KEY` is server-side only.
- The Supabase **service-role** key must never be put in the app or the repo.
  The function does not use it.

Tests for the function's logic (needs [Deno](https://deno.com) or Node 22+):

    cd supabase/functions/bucks-ai
    deno test logic_test.ts        # or: node --test logic_test.ts
