# BUCKS: Your Student Finance Manager 🐣💰

**A gamified personal finance application designed to make money management simpler, more engaging, and easier to understand.**
<img width="1080" height="1080" alt="BUCKS" src="/docs/assets/BUCKS Square Image.png" />

---

## My Project Repository

* **Public repository:** https://github.com/Vernuh/Bucks
* **Live app:** Not deployed yet T^T

## What It Is

**BUCKS: Your Student Finance Manager** is a gamified personal finance application designed to help users, especially students and young adults, develop better financial habits. It provides an engaging way to track income and expenses, manage budgets, monitor savings goals, and keep track of debts.

BUCKS features a friendly virtual companion named **Bucks**, who motivates users through daily missions, achievements, rewards, and AI-powered financial insights. By combining practical financial tools with gamification, BUCKS aims to make personal finance more approachable, interactive, and enjoyable.

The application is built with Flutter and uses Supabase for authentication and cloud data storage, with Gemini AI planned for the AI-powered assistant.

---

## Features

### 💰 1. Income and Expense Tracking

* Record income and expenses.
* Categorize financial transactions.
* View transaction history.
* Monitor how money is earned and spent.
* Keep financial records organized.

### 📊 2. Budget Planner

* Create and manage budgets.
* Set spending limits.
* Monitor expenses against budgets.
* Track remaining budget amounts.
* Improve spending awareness.

### 🎯 3. Savings Goals

* Create personalized savings goals.
* Set target amounts.
* Track savings progress.
* Monitor how much is saved and how much remains.
* Stay motivated while working toward financial goals.

### 💳 4. Debt Tracker

* Track money you owe to other people.
* Track money other people owe you.
* Record payments and amounts received.
* Monitor remaining balances.
* Set due dates and view debt status.

Debt records are kept separate from transactions so that creating a debt does not automatically count as income or an expense :P

### 📈 5. Reports and Charts

* Visualize income and expenses.
* Monitor savings progress.
* Compare savings and spending.
* Review financial activity.
* Understand financial habits through charts and summaries.

### 🏆 6. Daily Missions

* Complete daily financial activities.
* Develop consistent money-management habits.
* Earn Bucks rewards and experience points.
* Track mission completion.

### 🎖️ 7. Achievements and Rewards

* Unlock achievements by reaching financial milestones.
* Earn Bucks rewards and XP.
* Track progress and accomplishments.
* Use earned Bucks for supported companion customization items.

### 🐣 8. Bucks Virtual Companion

* Interact with a friendly virtual companion.
* Receive encouraging messages and financial reminders.
* Make financial management more engaging through gamification.
* Customize Bucks as supported features become available.

### 🤖 9. AI Financial Assistant

* Ask financial questions through the Bucks assistant.
* Receive general budgeting and saving guidance.
* Explore personalized financial insights based on available financial data.

The AI assistant is intended to provide supportive guidance, not professional financial advice. AI features depend on the Gemini integration being configured and available.

### 🌐 10. BucksBoard (not avail yet)

* View a leaderboard-style experience.
* Display user progress and earned Bucks or XP.
* Encourage positive engagement through friendly competition.

---

## Technologies Used

| Technology                        | Purpose                                 |
| --------------------------------- | --------------------------------------- |
| Flutter                           | Cross-platform application development  |
| Dart                              | Main programming language               |
| Material 3                        | User interface and design system        |
| Provider                          | State management                        |
| Supabase Authentication           | User registration and login             |
| Supabase Database                 | Cloud storage for user data             |
| Supabase Row Level Security (RLS) | Protect user-specific records           |
| Supabase Edge Functions           | Secure server-side AI integration       |
| Gemini AI                         | AI assistant and financial insights     |
| Git and GitHub                    | Version control and source code hosting |

---

## How to Run It

### Requirements

Install the following before running the project:

* Flutter SDK
* Dart SDK (included with Flutter)
* Git
* Visual Studio Code or another compatible IDE
* Google Chrome for Flutter Web
* A configured Supabase project

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
```

### 2. Navigate to the Project Folder

```bash
cd BUCKS
```

Use the actual folder name created when cloning the repository if it differs.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Environment Variables

Create a `.env` file in the project root by copying `.env.example`.

For example:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_PUBLIC_KEY=your_supabase_public_key
```

Replace the placeholder values with the appropriate public configuration from your Supabase project.

**Important:**

* Do not commit `.env` to GitHub (pls lang).
* Use only the Supabase public/anon or publishable key in the Flutter client.
* Never include a Supabase service-role key or Gemini API key in the Flutter application (!!!!!).
* Ensure `.env` is included in `.gitignore`.

### 5. Configure Supabase

Create or use a Supabase project and apply the database schema and migrations included in the repository.

Ensure that:

* Supabase Authentication is configured.
* Required database tables exist.
* Row Level Security (RLS) is enabled on user-specific tables.
* Policies restrict access to each user's own data.
* Any required Edge Functions are deployed.

Do not reset an existing database to install the project. Apply the appropriate migrations safely.

### 6. Configure Gemini AI (If Enabled)

The Gemini API key should be stored as a server-side Supabase Edge Function secret, not in the Flutter app.

For example, configure the secret using the Supabase CLI:

```bash
npx supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Deploy the relevant Edge Function using the project's existing Supabase setup instructions.

Only configure AI if the feature is implemented and required for the version you are running.

### 7. Run the Application

To run BUCKS in Google Chrome:

```bash
flutter run -d chrome
```

Alternatively, to run it using the web-server device:

```bash
flutter run -d web-server
```

Open the local URL displayed in the terminal if using the web-server option.

---

## How to Use

### 1. Create an Account or Log In

Register a new account or sign in using the existing authentication screen.

### 2. Explore the Dashboard

View the available financial summaries, shortcuts, and Bucks companion messages.

### 3. Add Transactions

Record income or expenses to keep your financial activity up to date.

### 4. Manage Your Budget

Set spending limits and review your expenses to understand how you are using your money.

### 5. Create Savings Goals

Set a savings target and monitor your progress as you work toward it.

### 6. Track Debts

Open the Debt Tracker from the Savings and Goals section. Add money you owe or money owed to you, then record payments as they occur.

### 7. Review Reports

Explore your financial charts and summaries to better understand your income, spending, and savings.

### 8. Complete Missions

Participate in available daily missions to build consistent financial habits and earn rewards.

### 9. Explore Bucks

Interact with the virtual companion, view achievements, and access available customization options.

### 10. Use the AI Assistant

If AI integration is enabled, ask Bucks for general financial guidance and insights.

---

## Project Structure

The project follows a feature-based Flutter structure. The exact files may vary as development continues.

```text
BUCKS/
├── android/
├── assets/
├── ios/
├── lib/
│   ├── app/
│   │   ├── app.dart
│   │   └── routes.dart
│   ├── models/
│   ├── providers/
│   │   └── app_state_provider.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── transactions/
│   │   ├── budget/
│   │   ├── savings/
│   │   ├── debt/
│   │   ├── reports/
│   │   ├── missions/
│   │   ├── bucksboard/
│   │   └── profile/
│   ├── services/
│   ├── widgets/
│   ├── theme/
│   │   └── app_theme.dart
│   └── main.dart
├── supabase/
│   ├── functions/
│   │   └── bucks-ai/
│   ├── migrations/
│   └── schema.sql
├── test/
├── .env.example
├── .gitignore
├── pubspec.yaml
├── README.md
├── AI-USAGE.md
└── SECURITY-CHECKLIST.md
```

Some folders may only exist if their associated features have been implemented.

---

## Database and Data Management

BUCKS uses Supabase to store and manage application data for authenticated users.

Depending on the implemented features, the database may include tables for:

* User profiles
* Transactions
* Budgets
* Savings goals
* Debts
* Missions
* Achievements
* Bucks rewards and customization

The application uses Provider for shared in-app state and a service layer to communicate with Supabase.

### Data Privacy

Row Level Security (RLS) is used to restrict access to user-specific records. Users should only be able to access or modify the records they own.

Debt information is stored separately from savings goals and transactions to maintain clear financial records.

---

## Security

BUCKS is designed to keep user data and credentials protected.

Security practices include:

* Keeping `.env` out of version control.
* Using only public client-safe Supabase credentials in Flutter.
* Keeping service-role credentials out of the client.
* Storing the Gemini API key on the server side when AI integration is enabled.
* Using Supabase RLS to protect user-specific financial records.
* Avoiding real personal or financial information in sample data.
* Validating user input before submitting financial records.

Before public release, the repository's commit history, environment files, and configuration should be checked for accidentally committed secrets or private information.

---

## AI Usage

BUCKS uses AI assistance during development and may provide AI-powered features within the application through Gemini.

AI tools may be used to assist with:

* Code generation and debugging.
* Understanding Flutter and Supabase implementation.
* Improving application structure.
* Drafting documentation.
* Developing the Bucks AI assistant and financial insights.

AI-generated code and suggestions should be reviewed, tested, and adapted to the project's requirements.

For detailed disclosure of AI tools and how they were used, see:

[AI-USAGE.md](https://github.com/Vernuh/Bucks/blob/main/AI-USAGE.md)

---

## Testing

The application should be tested to verify that its main features work as expected.

Recommended checks include:

* User registration and login.
* Authentication session restoration.
* Adding, viewing, updating, and deleting transactions.
* Creating and managing budgets.
* Creating and updating savings goals.
* Adding debts and recording payments.
* Calculating remaining debt balances correctly.
* Completing missions and receiving rewards.
* Loading user-specific data from Supabase.
* Ensuring users cannot access other users' private records.
* Running the app on supported screen sizes.

### Run Static Analysis

```bash
flutter analyze
```

### Run Tests

```bash
flutter test
```

### Run the Application

```bash
flutter run -d chrome
```

The results of these checks should be updated to reflect the actual tests performed on the submitted version.

---

## Known Issues and Future Improvements

BUCKS is an ongoing project, and features may continue to be improved.

Potential future improvements include:

* Completing and refining the AI assistant.
* Adding more Bucks companion animations and reactions.
* Expanding Bucks customization options.
* Improving the responsiveness of screens across devices.
* Enhancing financial charts and reports.
* Improving mission variety and achievement tracking.
* Expanding testing and error handling.
* Deploying the web application for public access.

Only features verified in the submitted version should be described as fully implemented.

---

## Presentation

| File | What goes in it |
| --- | --- |
| [01-proposal.md](01-proposal.md) | the problem, the users, the scope, the storage decision |
| [02-mockup.md](02-mockup.md) | the mockup images, plus your wireframes and screen flow |
| [03-design-system.md](03-design-system.md) | palette, type scale, spacing, components, **plus a visual PDF or image** |
| [04-weekly-reports.md](04-weekly-reports.md) | one short entry per week, added as you go |
| [05-demo-video.md](05-demo-video.md) | the recording and what it shows |
| [06-security-and-privacy.md](06-security-and-privacy.md) | the checklist, filled in and dated |
| `assets/` | screenshots, wireframe photos, diagrams |

---

## Acknowledgments

BUCKS was developed cause my ex likes to save up and keep tracking her money (lol shout out to you maem ure my muse :>) and she doesn't feel like any of the finance app can fit her perfectly so I developed BUCKS the way she likes it, the way how she wants to use it, and the way that will make saving money easier for her. (they call me yearner fianl boss for a reason)

Also very special shout-out to my so so so cool professor, sir TJ wahahah, for the guidance, patience, encouragement, and lessons throughout this project. Your support and the way you encouraged us to actually build, experiment, make mistakes, and learn from them made a huge difference in my development as a student and aspiring developer.

so yeah pls enjoy the app, it was my first project :P

---

**BUCKS — Small steps, smarter money habits.** ~ Verhuh, Bucks creator

License
---
The source code of BUCKS is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Third-party assets used in BUCKS, including artwork, icons, fonts, images, sounds, libraries, and other resources, are subject to their respective licenses and are not necessarily covered by the MIT License.
