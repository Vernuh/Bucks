# Security Checklist

## Secrets and credentials

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 1 | No API key, token, password, or other secret is hardcoded in `lib/`, including comments and commented-out code | **Yes** | BUCKS uses environment configuration for client-side Supabase values. Private credentials such as the Gemini API key and Supabase service-role key are not stored in Flutter source code. |
| 2 | Private credentials are stored securely and an example configuration is provided | **Yes** | BUCKS uses `.env` for client configuration and `.env.example` as a safe template. The `.env` file must not be committed to GitHub. |
| 3 | No Android keystore, `key.properties`, or signing credentials are committed | **N/A** | BUCKS is currently being developed primarily as a Flutter Web application and does not currently include Android signing credentials. |
| 4 | Git history has been checked for accidentally committed secrets | **No** | The complete Git history still needs to be checked using the actual BUCKS repository before final public release. |
| 5 | Any credential that was previously committed has been rotated | **To Verify** | No known private credentials should be committed, but the complete Git history must be reviewed before this can be confirmed. |

---

## GitHub Actions

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 6 | No secret values are written directly in GitHub Actions workflow files | **N/A** | BUCKS does not currently rely on GitHub Actions workflows for its main application functionality. |
| 7 | GitHub Actions secrets are used when workflows require credentials | **N/A** | No GitHub Actions deployment workflow is currently part of the BUCKS project. |
| 8 | Workflow logs do not expose secrets | **N/A** | No GitHub Actions workflow logs are currently being used for BUCKS. |
| 9 | Signing credentials are protected if a signed mobile build is created | **N/A** | BUCKS is currently being developed as a Flutter Web application. |
| 10 | Build artifacts do not contain private keys or credentials | **To Verify** | This should be checked again before publishing any generated build artifacts. |
| 11 | Third-party GitHub Actions are pinned securely | **N/A** | BUCKS does not currently use third-party GitHub Actions. |
| 12 | GitHub secret scanning and push protection are enabled | **To Verify** | This must be checked in the GitHub repository settings before the repository is made public. |

---

## Backend and database security

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 13 | Supabase Row Level Security is enabled for user-specific tables | **Yes / Verify** | BUCKS uses Supabase for authentication and persistent application data. RLS should be enabled for user-specific tables such as profiles, transactions, budgets, savings goals, debts, and other private user data. |
| 14 | Supabase policies restrict users to their own records | **Yes / Verify** | User-specific records should be protected using the authenticated user's Supabase identity, typically through `auth.uid() = user_id`. This must be verified in the live Supabase project. |
| 15 | The `debts` table is protected by RLS | **Yes / Verify** | The Debt Tracker uses a separate `debts` table. Users must only be able to view, create, update, and delete their own debt records. |
| 16 | Supabase service-role credentials are not included in the Flutter application | **Yes** | The Flutter client should only use the public/anon/publishable Supabase key. The service-role key must remain server-side. |
| 17 | Gemini API credentials are stored server-side | **Yes / Verify** | BUCKS uses a Supabase Edge Function for Gemini integration. The `GEMINI_API_KEY` should be stored as a Supabase Edge Function secret and must not be included in Flutter or GitHub. |
| 18 | Authentication protects private user data | **Yes / Verify** | BUCKS uses Supabase Authentication. The application should require an authenticated user before accessing private financial records. |
| 19 | Signed-out users cannot access another user's financial data | **To Verify** | This must be manually tested with Supabase Auth and RLS before final submission. |
| 20 | Sample/seed data is fictional and contains no real people's financial information | **Yes** | BUCKS sample data should use fictional/default values and must not contain classmates' or other people's real financial information. |

---

## Input and application surface

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 21 | Financial inputs are validated before being saved | **Yes / Verify** | BUCKS validates financial input such as transaction amounts. The Debt Tracker also requires valid positive amounts and must prevent payments from exceeding the remaining debt. |
| 22 | Debt amounts cannot be negative | **Yes / Verify** | The Debt Tracker should reject negative original amounts and negative payments. |
| 23 | Debt payments cannot exceed the remaining balance | **Yes / Verify** | A debt payment must not exceed `originalAmount - amountPaid`. |
| 24 | Sensitive data is not exposed through error messages | **Yes / Verify** | Supabase and AI errors should be handled without exposing private credentials or unnecessary database information to users. |
| 25 | Nothing secret is recoverable from the shipped Flutter application | **Yes / Verify** | The Flutter application must not contain the Gemini API key, Supabase service-role key, database password, or other private server credentials. |

---

## Repository and privacy

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 26 | No student number, personal email, phone number, home address, password, or other unnecessary personal information is committed | **To Verify** | The final repository and Git history must be checked before publication. |
| 27 | No classmates' or other people's private financial information is included | **Yes** | BUCKS should use fictional/sample financial data for demonstrations and testing. |
| 28 | `.env` is excluded from Git | **Yes / Verify** | `.env` must be listed in `.gitignore`. Only `.env.example` should be committed. |
| 29 | `.dart_tool/` and `build/` are excluded from Git | **Yes / Verify** | Flutter-generated files should be excluded through `.gitignore`. |
| 30 | Dependencies come from trusted package sources | **Yes** | BUCKS uses Flutter/Dart packages such as Provider and Google Fonts from the normal Dart/Flutter package ecosystem. |
| 31 | Images, fonts, and other assets are properly licensed or credited | **Yes / Verify** | BUCKS uses Google Fonts through the `google_fonts` package. Any additional images, artwork, or mascot assets should be checked for appropriate usage rights. |
| 32 | Repository visibility is intentional | **To Verify** | The final GitHub repository settings must be checked before making the repository public. |
| 33 | No secrets exist in previous commits | **To Verify** | The complete Git history needs to be scanned before the final public push. |

---

## AI and Gemini security

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 34 | Gemini API key is not stored in Flutter source code | **Yes / Verify** | The Gemini API key should only exist as the `GEMINI_API_KEY` secret used by the Supabase Edge Function. |
| 35 | Gemini requests are routed through the secure backend function | **Yes / Verify** | BUCKS uses the architecture: Flutter → `AiService` → Supabase Edge Function → Gemini. |
| 36 | The Gemini API key is not committed to GitHub | **Yes / Verify** | The key must remain in Supabase's server-side secrets and never be placed in `.env`, Dart code, or committed files. |
| 37 | AI does not invent the user's financial information | **Yes / Verify** | The Bucks AI assistant should only use financial information actually available to it and should not fabricate balances, transactions, debts, or savings. |
| 38 | AI errors are handled safely | **Yes / Verify** | Failed AI requests should return a user-friendly error rather than exposing API keys, server errors, or sensitive backend information. |

---

## Debt Tracker security

| # | Check | Yes / No / N/A | Evidence |
|---|---|---|---|
| 39 | Debt data is stored separately from savings goals | **Yes** | BUCKS uses a dedicated `debts` table rather than storing debt records inside `savings_goals`. |
| 40 | Every debt belongs to an authenticated user | **Yes / Verify** | The `debts` table uses `user_id` to associate each debt with its owner. |
| 41 | Users cannot access another user's debts | **Yes / Verify** | Supabase RLS should restrict access using the authenticated user's ID. |
| 42 | Creating a debt does not automatically create a fake transaction | **Yes** | A debt represents an obligation and should not automatically be treated as income or expense. |
| 43 | Actual debt payments are validated before being recorded | **Yes / Verify** | Payments must be positive and cannot exceed the remaining balance. |
| 44 | Deleting a debt requires confirmation | **Yes / Verify** | The Debt Tracker should use a confirmation dialog before permanently deleting a debt. |

---

## Anything found and fixed

The current BUCKS architecture uses **Supabase Authentication and Database** for user authentication and persistent application data. User-specific data is protected through **Row Level Security (RLS)**.

BUCKS also uses a **Supabase Edge Function for Gemini AI**. The Gemini API key is stored server-side as a Supabase Edge Function secret and must not be placed inside the Flutter application or committed to GitHub.

The Debt Tracker uses a dedicated `debts` table with authenticated user ownership and RLS protection. Debt records are kept separate from savings goals, and creating a debt does not automatically create a financial transaction.

Before the final public release, the following checks still need to be manually verified:

- [ ] Scan the complete Git history for secrets.
- [ ] Confirm `.env` is ignored by Git.
- [ ] Confirm `.env.example` contains only placeholders.
- [ ] Confirm the Gemini API key is stored only as a Supabase Edge Function secret.
- [ ] Verify RLS is enabled on every user-specific Supabase table.
- [ ] Verify RLS policies prevent cross-user data access.
- [ ] Test that one user cannot access another user's financial data.
- [ ] Enable and check GitHub secret scanning and push protection.
- [ ] Check the final GitHub repository for personal information.
- [ ] Confirm repository visibility is intentional.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Test Supabase Authentication.
- [ ] Test transactions and financial data persistence.
- [ ] Test the Debt Tracker.
- [ ] Test the Gemini AI assistant.
- [ ] Test the application after logging out and logging back in.

## Final Security Principle

No Supabase service-role key, Gemini API key, database password, authentication secret, or other private credential should ever be committed to the public BUCKS repository.

Public client configuration may be included when required by the application, but access to private user data must be enforced through Supabase Authentication and Row Level Security.