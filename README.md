# Setline

A comms app for commercial and photo shoots. One space per shoot with role-based chat, a push-to-talk walkie for crew, client frame approvals tied to the shot list, call sheet info, and a read-only archive when the job wraps.

The clickable prototype is `reference/prototype.html`. Open it in any browser. It's the reference for every screen, flow and word in the app.

## Where things are

| Folder | What's in it |
| --- | --- |
| `src/app/` | The app's screens. One file per screen. |
| `src/ui/` | Colors, fonts and shared pieces like buttons. |
| `src/lib/` | The connection to the database. |
| `supabase/migrations/` | The database design and its privacy rules. |
| `supabase/seed.sql` | The Halden Skincare sample shoot. |
| `supabase/tests/` | Automatic checks that the privacy rules and approvals work. |
| `reference/` | The prototype. |

## Progress

- [x] **Setup:** app shell, database, privacy rules, sample data, tests
- [ ] Sign in and projects
- [ ] Channels and chat
- [ ] Walkie (app open)
- [ ] Client review and shot list
- [ ] Call sheet and wrap
- [ ] Notifications
- [ ] Walkie from the lock screen
- [ ] TestFlight

## Setup, step by step

You don't need to install anything on your computer for these steps. Claude does the technical parts once the keys are in place.

### 1. Make the accounts

| Account | Where | Notes |
| --- | --- | --- |
| Supabase | [supabase.com](https://supabase.com) | New project named `setline`, region East US. Save the database password it shows you. |
| Expo | [expo.dev](https://expo.dev) | Free plan is fine. |
| Apple Developer Program | [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll) | Needed before the app can go on your phone. Approval takes a day or two. |

### 2. Hand the keys to Claude

Never paste keys into a chat. Add each one as a secret in the Claude project's settings: **Project settings > Cloud environment > gear icon**, then add each of these. Use the names exactly as written.

| Name | Where to find it |
| --- | --- |
| `SUPABASE_PROJECT_REF` | The string after `/project/` in your Supabase dashboard's web address. |
| `SUPABASE_DB_PASSWORD` | The password you saved when you made the project. Forgot it? Project Settings > Database > Reset database password. |
| `SUPABASE_ACCESS_TOKEN` | Supabase > your avatar > Account preferences > Access Tokens > Generate new token. |
| `EXPO_TOKEN` | expo.dev > your avatar > Account settings > Access tokens > Create token. |

### 3. What Claude does next

1. Connects to your Supabase project and loads the database design and the sample shoot.
2. Turns on the automatic tests on GitHub. You can see them under the repo's **Actions** tab, where green means every privacy rule passed.
3. Writes the app's public Supabase address and key into the build settings. These two are safe to ship inside the app, because the privacy rules protect the data.

### 4. Look at the sample shoot

In the Supabase dashboard, open **Table Editor** and pick `projects`. You'll see **Halden Skincare**. The `channels`, `messages`, `shots` and `frames` tables hold its chat, shot list and frames, matching the prototype.

### Sample logins

Every sample person signs in with the password `setline-demo`. They're for testing only.

| Person | Email | Role |
| --- | --- | --- |
| Maya Okafor | maya@halden.example | Producer |
| Theo Lind | theo@halden.example | Photographer |
| Rafi Mendez | rafi@halden.example | Digi tech |
| Jonah Pike | jonah@halden.example | Crew, 1st Assistant |
| Dee Alvarez | dee@halden.example | Crew, Gaffer |
| Sun Park | sun@halden.example | Crew, Key grip |
| Lena Sato | lena@halden.example | Glam, Hair & makeup |
| Priya Nair | priya@halden.example | Glam, Wardrobe |
| Carla Voss | carla@halden.example | Agency |
| Erin Shaw | erin@halden.example | Client |
| Ama Boateng | ama@halden.example | Talent |

**Before real shoots, delete the sample people.** In Supabase, open **SQL Editor** and run:

```sql
delete from public.projects where name = 'Halden Skincare';
delete from auth.users where email like '%@halden.example';
```

## For developers

```bash
npm install
cp .env.example .env          # fill in EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY
npm run typecheck
npx supabase start            # local Supabase in Docker, with migrations and seed
npm run db:test               # pgTAP tests in supabase/tests
npm run db:types              # regenerate src/lib/database.types.ts
npx eas build --profile development --platform ios   # development build (needs Apple membership)
npm start                     # start the dev server for the development build
```

Rules that must hold, all enforced in the database and covered by the tests:

- A user only reads or writes rows for projects they belong to, and only channels their role can see.
- Clients, agency and talent never get a walkie channel or a crew channel.
- Approving a frame (`approve_frame`) sets it to approved, other pending frames for the same look to alt, checks off the look, and posts in client-review, all in one transaction.
- A wrapped project rejects every change until the producer reopens it.
