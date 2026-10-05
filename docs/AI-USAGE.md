# BUCKS: Your Student Finance Manager — AI Usage

I developed BUCKS with AI assistance throughout the project. I used AI tools mainly as coding assistants when I was implementing something unfamiliar, debugging a problem, figuring out how different services should connect, or working on larger features.

The main AI tools I used were OpenAI, Claude, and Gemini.

AI was used throughout development, but I was also responsible for the application's product direction, frontend decisions and coding, feature integration, testing, debugging, backend configuration, and modifying AI-generated code.

I did not treat AI-generated code as automatically correct. I tested changes in the actual BUCKS application, changed implementations when they did not behave the way I wanted, and kept the parts I could understand and maintain.

## 1. How I Used AI

### 1. Project Structure and Initial Setup

I used AI when I was first organizing BUCKS as a Flutter application. I was figuring out how to separate the screens, models, services, widgets, themes, and application routing while also deciding how shared application data should work.

AI suggested using a structured Flutter architecture and Provider for shared application state. I kept the general idea of separating different parts of the application, but I changed the structure to fit BUCKS instead of copying the suggestion exactly.

I also decided which features needed their own screens and which parts should be separated into folders. My goal was to make the project easier to expand as I added more finance features.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/1e440672f27258c06ea837c839f063a3533821b5)

### 2. Navigation Bar

I personally built the navigation bar for BUCKS because I wanted to follow what I build using the project mock-up. Also for the main features of the application to be accessible from one place. I worked on the navigation structure and connected the different sections of the application to it.

While implementing it, I ran into errors with the navigation, so I used AI to help me understand what was causing the problems and how I could fix them. I used the suggestions to debug my existing implementation rather than treating the generated code as the final solution.

After making the changes, I tested the navigation in the running application to make sure the different screens could be accessed correctly and that the navigation worked with the rest of the application.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/53d042a7c69e4a038a2809f53d02bce1f1da4b03)

### 3. Add Transaction

I worked on the Add Transaction feature because transaction tracking is one of the main functions BUCKS needed. I implemented the feature for adding financial transactions such as income and expenses and connected it with the existing application flow.

I used AI when I needed help with parts of the Flutter implementation and debugging. I then tested the transaction flow in the actual application and adjusted the implementation to work with the rest of BUCKS.

The main behavior of the feature was based on how I wanted users to record their financial activity in BUCKS and also followed the mock-up I built.

I also worked on connecting the Add Transaction feature to the overall application structure. The routing setup added the `addTransaction` route, while the `MainShell` placed the Add Transaction screen directly in the main navigation as the central “Add” button. I also helped establish the `Transaction` model with fields for the transaction type, category, amount, date, and optional notes. These changes followed the mock-up I created, where adding a transaction was intended to be one of the main actions users could access quickly from the navigation bar.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/53d042a7c69e4a038a2809f53d02bce1f1da4b03)

### 4. BUCKS Frontend and Screen Development

A large part of my work on BUCKS involved developing and modifying the frontend screens and how users interact with the application.

I decided how I wanted BUCKS to look and how the different financial features should be presented. The goal was to make the application feel more friendly and game-like instead of looking like a traditional finance application.

In the `21a4289` frontend update, I worked on several major screens and UI components, including the Home, Bucks, Savings, and Profile screens. I also worked on the layout and interactions within these screens.

Some of the frontend work included:

- developing the blue and yellow BUCKS visual identity
- organizing the layout of the main screens
- designing cards, buttons, headers, and other reusable UI elements
- developing the Bucks screen with the Bucks character and motivational message
- adding the Achievements and Chat sections to the Bucks screen
- connecting Customize Bucks and BucksBoard to their respective screens
- developing the Savings screen and its financial sections
- developing the Profile screen with the user's information, savings, expenses, and account actions
- making the screens follow the mock-up and overall visual style I wanted for BUCKS

I used AI to help with parts of the Flutter implementation, especially when working with larger screen layouts and debugging existing code. However, I reviewed the generated code, tested the screens in the actual application, and modified the implementation when it did not match the design or behavior I wanted.

This commit was an important frontend development stage because it established much of the visual structure and user experience of the main BUCKS screens. The frontend was then further developed through later commits as additional features were added.

**Commit:** [View commit](https://github.com/zii4h/Jova/commit/3b605963bafc00490da89adc279a10b9d77a0d07)
**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/1e5a5b6a8ff565b15636b8be1be4affe90bba743)
**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/2bb3a4fc1856a3480a434411f5d82f023da5ad2d)

### 5. Supabase Authentication and Database

After watching at least 10 yt videos and reading a lot of blogs in stackoverflow I managed to understans how supabase auth and database worked. I tried writing the code for the supabase and used AI while setting up Supabase because I had not worked with Supabase Authentication, database policies, and Row Level Security in this type of application before.

I used AI to understand and code parts of:
- Supabase Authentication
- database tables
- environment variables
- Row Level Security
- public/anon keys
- protecting backend secrets
- connecting Flutter to Supabase

AI helped me understand the architecture and suggested ways to connect Flutter with Supabase.

I personally created and configured the Supabase project and database and tested the authentication and database functionality. I also made the decision to move from the local database approach to Supabase because BUCKS needed a backend that could support authenticated users and persistent cloud data. One important part I learned was that the Supabase service-role key should not be placed inside the Flutter application.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/9fe14db765857103a320a12af9df6efd57bc960e)

### 6. Gemini AI Chat

I wanted BUCKS to have an AI-powered chat feature, so I used AI to help me figure out how to connect Gemini to the application securely.

I specifically needed to understand how the Gemini API should communicate with Flutter without exposing the API key in the client application.

The architecture I used became:

BUCKS Flutter App
        ↓
    AiService
        ↓
Supabase Edge Function
        ↓
     Gemini API

I used AI to help with the implementation and to understand how the Edge Function should communicate with Gemini.

I personally configured the backend resources, connected the AI functionality to BUCKS, and tested the Edge Function deployment. I also worked through configuration problems during the setup. One of the important security decisions I learned was keeping the Gemini API key on the backend rather than placing it inside the Flutter application.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/e112e1cb7e359cd5a143271afab5f9da6bb1f237)

### 7. Debt Tracker

I decided to add a Debt Tracker as another part of BUCKS's financial management features. I used AI to help me plan how debt information should be structured and how the feature could be integrated into the existing Savings & Goals section.

I decided that the feature should support:
- Money I Owe
- Money Owed to Me
- debt amount
- amount paid
- due dates
- debt status

I also modified the code that the ai gave me so that a debt should not automatically create an income or expense transaction because a debt record and an actual financial transaction represent different things.

AI helped with parts of the implementation, while I decided how the feature should behave and integrated it into the existing BUCKS structure. I tested the feature after integrating it with the application.

---

## 2. Where the AI Got It Wrong

### 1. Provider Dependency

One problem I encountered early in development was that AI-generated Flutter code used Provider, but the dependency was not correctly available in my project yet. The code itself was fine, but the required package had not been added to the Flutter project.

I identified the problem through the Flutter errors, added and configured Provider, and tested the application again to make sure the code worked correctly.

This taught me that AI can generate code based on packages that are not necessarily installed in the actual project. I need to check the project's dependencies instead of assuming the generated code will work immediately.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/61c3e86234de157acd6603f2dfd9f16406bf581b#diff-3de8cd4c4a3eaeffa37daab4df86ad6a8da7ac14ae17652982def084bb4acb7b)

### 2. Flutter RenderBox/Layout Error

During development, I encountered a Flutter rendering and layout assertion involving RenderBox. The generated implementation looked correct when reading the code, but it did not behave correctly when the screen was actually rendered in the application.

I found the problem while running and testing the affected screen. I inspected the widget hierarchy and looked at how the parent and child widgets were being given their available space. I then adjusted the layout implementation and tested the screen again to make sure the error no longer occurred.

This showed me that Flutter layouts cannot always be judged just by looking at the code. A widget hierarchy may appear reasonable but still fail when the actual parent and child constraints are applied during rendering. It taught me to rely on testing the application itself and not only on whether the generated code looks correct.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/21a42898a099cdc37c9e95859269256be8b41a79)
**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/c4c7b8e5da93f30ea907e2d492ee0f23ebfca9ee)
**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/61c3e86234de157acd6603f2dfd9f16406bf581b)

### 3. Incorrect .env Format

While setting up Supabase and Gemini, I initially used the wrong format for the .env file. I formatted it more like JSON instead of using the normal environment-variable format.

The correct format was:
SUPABASE_URL=...
SUPABASE_PUBLIC_KEY=...

The problem became more noticeable when the application tried to use the malformed value as part of the Supabase URL. This caused authentication requests to fail because the URL contained invalid characters. The AI also contributed to the problem because its configuration check mainly looked for empty values. It did not initially validate whether the values were properly formatted, so an invalid .env value could pass the check.

I fixed the .env file and improved the application's configuration validation so it could detect invalid characters and malformed URLs before the application tried to connect to Supabase. This taught me that environment variables have a specific syntax and should not be treated like regular configuration objects. It also showed me that validation should check not only whether a value exists, but whether the value is actually valid.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/9fe14db765857103a320a12af9df6efd57bc960e)

### 4. AI-Generated Code Did Not Match the Existing Project Structure

Another issue I encountered was when the AI generated or modified code based on an assumed project structure that did not completely match my actual BUCKS project. Some files, routes, and existing implementations were different from what the generated code expected. This caused parts of the implementation to require additional changes before they could work correctly with the rest of the application.

I compared the generated code with my existing project structure, adjusted the imports and connections, and tested the affected features again. This taught me that AI needs to understand the existing codebase before making large changes. I learned to check how my current files, routes, and providers are connected instead of simply replacing existing code with generated code.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/1e5a5b6a8ff565b15636b8be1be4affe90bba743)

---
## 3. Who Wrote What

AI was involved heavily in the development of BUCKS, but there are also significant parts of the application that I personally designed, implemented, modified, configured, and tested.

My overall contribution was approximately 30–40% of the implementation work. This is an approximate description of my contribution rather than an exact measurement of lines of code.

More importantly, I was responsible for deciding what BUCKS should do, how the application should be organized, how the features should behave, and how the different parts should work together.

### Product Direction

I personally developed the overall concept and direction of BUCKS.

I decided that BUCKS would combine:
- personal finance management
- income and expense tracking
- budgeting
- savings goals
- reports and graphs
- missions
- rewards
- XP
- Bucks customization
- AI assistance
- debt tracking

I also decided that BUCKS should have a friendly, game-like identity instead of looking like a traditional banking application.

### Frontend Development

I personally worked on the frontend throughout the project.

Some of the areas I worked on include:

- lib/screens/
- lib/widgets/
- lib/theme/
- lib/app/routes.dart

I worked on:
- navigation
- screen organization
- transaction UI
- savings UI
- reports and graphs
- Bucks functionality
- customization
- buttons and interactions
- connecting new features to existing screens
- testing and correcting UI behavior

The navigation bar is one example where I personally implemented the feature and used AI mainly to debug errors in my implementation.

**Navigation:** [View commit](https://github.com/Vernuh/Bucks/commit/53d042a7c69e4a038a2809f53d02bce1f1da4b03)
**Add Transaction:** [View commit](https://github.com/Vernuh/Bucks/commit/2bb3a4fc1856a3480a434411f5d82f023da5ad2d)
**Savings Graphs:** [View commit](https://github.com/Vernuh/Bucks/commit/c4c7b8e5da93f30ea907e2d492ee0f23ebfca9ee)
**Customize Bucks:** [View commit](https://github.com/Vernuh/Bucks/commit/61c3e86234de157acd6603f2dfd9f16406bf581b)

### Backend and Data

I also personally worked on the application's data and backend direction.

This included:
- deciding what data BUCKS needed
- working on persistence
- implementing the local database approach
- moving from local storage to Supabase
- configuring Supabase Authentication
- configuring the database
- working with environment variables
- testing authenticated data
- integrating the AI backend

**Local Database:** [View commit](https://github.com/Vernuh/Bucks/commit/297d303e681d4a7119ca32b37b09163373062122)
**Supabase:** [View commit](https://github.com/Vernuh/Bucks/commit/9fe14db765857103a320a12af9df6efd57bc960e)
**AI Chat:** [View commit](https://github.com/Vernuh/Bucks/commit/e112e1cb7e359cd5a143271afab5f9da6bb1f237)
**Debt Tracker:** [View commit](https://github.com/Vernuh/Bucks/commit/c1898f206a9823481722a9d5bca1b72258c6b5d7)

### Testing and Debugging

A significant part of my contribution was testing whether the features actually worked together.

I did not consider a feature finished just because the code compiled.

I tested:
- navigation
- transactions
- database persistence
- authentication
- Supabase integration
- AI chat
- Edge Function deployment
- frontend layouts
- new feature integration

When something did not work, I used AI to help understand the error when necessary, then modified the implementation and tested it again.

---
## 4. AI-Written Code That I Understand

One example of AI-assisted code that I can explain is the Gemini integration. The Flutter application should not contain the private Gemini API key. Instead, the request follows this structure:

ChatScreen
     ↓
 AiService
     ↓
Supabase Edge Function
     ↓
  Gemini API

The ChatScreen handles the user interface, while AiService handles communication between the Flutter application and the backend. The Supabase Edge Function acts as the backend layer between the Flutter application and Gemini, communicating with Gemini using the protected API key. I understand why this architecture is preferable to putting the Gemini API key directly inside the Flutter application because it keeps the sensitive API key on the server side instead of exposing it in the client app.

**Commit:** [View commit](https://github.com/Vernuh/Bucks/commit/e112e1cb7e359cd5a143271afab5f9da6bb1f237)
---
## 5. Development Progress

| Date               | Feature                             | Commit    |
| ------------------ | ----------------------------------- | --------- |
| July 22, 2026      | Project framework initialized       | `a530bb2` |
| September 23, 2026 | Initial files                       | `1e44067` |
| September 27, 2026 | Navigation bar                      | `53d042a` |
| September 27, 2026 | Add Transaction                     | `2bb3a4f` |
| September 27, 2026 | Updated `.gitignore`                | `a0064c1` |
| September 30, 2026 | Bucks functionality                 | `1e5a5b6` |
| October 1, 2026    | Screen updates                      | `21a4289` |
| October 2, 2026    | Savings graphs                      | `c4c7b8e` |
| October 2, 2026    | Customize Bucks                     | `61c3e86` |
| October 2, 2026    | Local database                      | `297d303` |
| October 3, 2026    | Supabase Auth and Database          | `9fe14db` |
| October 3, 2026    | AI-integrated chat                  | `e112e1c` |
| October 3, 2026    | Debt Tracker                        | `c1898f2` |
| October 4, 2026    | README, security checklist, cleanup | `e14bd4f` |

---
## 6. Development Workflow

My general workflow was:

1. Decide what BUCKS should do
        ↓
2. Plan the feature
        ↓
3. Implement the feature
        ↓
4. Ask AI for help when I get stuck
        ↓
5. Review the suggested solution
        ↓
6. Integrate or modify the solution
        ↓
7. Run the application
        ↓
8. Find errors or problems
        ↓
9. Fix and test again
        ↓
10. Commit the working version

I used AI as a development assistant rather than treating it as the person building the application for me. And still, I needed to understand the project structure, make decisions about the features, configure external services, test the application, and decide whether an AI suggestion actually made sense for BUCKS.

---
## 7. AI Tools Used

OpenAI
I used OpenAI for:
- architecture discussions
- debugging
- Supabase guidance
- security guidance
- documentation
- understanding errors
- deciding how different features could work together

Claude
I used Claude for:
- implementing larger Flutter features
- feature integration
- working through larger changes to the existing project

Gemini

Gemini is also used as part of BUCKS itself.

It is intended to power:
- Buck's AI chat
- financial insights
- personalized financial assistance
---
## 8. Final Reflection
AI significantly increased my development speed, especially when working with Flutter, Supabase, and backend integration. However, using AI also showed me that generated code is not automatically correct.

I encountered problems involving:
- dependencies
- Flutter layouts
- environment configuration
- backend setup
- integrating different features

I had to test the generated code, identify problems, modify implementations, and make decisions about how each feature should work. The project also evolved as I learned more, such as initially experimenting with a local database before deciding that Supabase was a better fit for BUCKS. The most important thing I learned was that generating code is not the same as building an application because I still needed to understand how the different pieces worked together, make design and architecture decisions, test the application, and fix problems when the generated solution did not work. AI helped me build BUCKS faster, but I was still responsible for turning those suggestions into a working application.

---
## AI Credit

AI tools played an important role in the development of BUCKS by helping me with code implementation, debugging, technical guidance, and understanding technologies that were new to me. I did not simply use the generated code as-is; I tested it in the actual application, identified issues, and modified the implementation step by step based on my requirements and what I learned during development.

The work documented in this file represents the parts of BUCKS that I reviewed, tested, and can explain and defend myself.