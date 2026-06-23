# Setup Guide - Frat Finance Tracker

## ✅ Completed So Far:

1. **Database Schema Designed** (`DATABASE_SCHEMA.md`)
   - Invitation system
   - Brother self-registration
   - Payment plans support
   - Payment tracking

2. **Project Structure Created**
   - Folder structure is ready
   - `pubspec.yaml` configured with all dependencies
   - `.gitignore` and `.env.example` created

3. **Documentation**
   - Technical plan
   - Roadmap
   - Client questionnaire

---

## 🔄 Currently In Progress:

**Flutter Installation** - Homebrew is downloading Flutter (277MB)
- This may take 10-30 minutes depending on your internet speed
- Installation is running in the background

---

## ⏭️ Next Steps (Once Flutter Finishes):

### 1. Complete Flutter Setup (5 minutes)

```bash
# Check if Flutter is installed
/opt/homebrew/bin/flutter --version

# If yes, initialize the Flutter app
cd /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker
/opt/homebrew/bin/flutter create . --org com.fratfinance --platforms=ios,android

# Install dependencies
/opt/homebrew/bin/flutter pub get

# Run code generation
/opt/homebrew/bin/flutter pub run build_runner build
```

### 2. Set Up Supabase (15-20 minutes)

**Go to:** https://supabase.com

1. **Create a new project**
   - Project name: `frat-finance-tracker`
   - Database password: (save this!)
   - Region: Choose closest to you

2. **Get your API keys**
   - Go to Project Settings → API
   - Copy `Project URL` and `anon/public key`

3. **Create `.env` file**
```bash
cp .env.example .env
# Edit .env and add your Supabase credentials
```

4. **Create database tables**
   - Go to Supabase SQL Editor
   - Run the SQL from `DATABASE_SCHEMA.md`
   - (I'll provide the complete SQL script)

### 3. Configure iOS/Android (10-15 minutes)

**For iOS:**
```bash
cd ios
pod install
cd ..
```

**For Android:**
- Already configured via `flutter create`

**For Firebase (Push Notifications):**
1. Go to https://console.firebase.google.com
2. Create new project: `frat-finance-tracker`
3. Add iOS app
4. Add Android app
5. Download config files

---

## 📋 Week 1 Development Tasks (10 hours):

### Day 1-2: Core Setup (3-4 hours)
- [ ] Wait for Flutter installation
- [ ] Initialize Flutter project
- [ ] Set up Supabase
- [ ] Create database tables
- [ ] Configure Firebase
- [ ] Test app runs on simulator

### Day 3-4: Authentication (3-4 hours)
- [ ] Build login screen
- [ ] Build signup screen (with invitation code)
- [ ] Implement Supabase auth
- [ ] Create auth state management with Riverpod
- [ ] Test login/signup flow

### Day 5: Navigation & Dashboard (3-4 hours)
- [ ] Set up go_router
- [ ] Create brother dashboard
- [ ] Create VP of Finance dashboard
- [ ] Test navigation between screens

**Goal:** By end of Week 1, have working auth and basic navigation

---

## 🛠️ Development Environment Checklist:

- [ ] Flutter installed via Homebrew
- [ ] Xcode installed (for iOS development)
- [ ] Xcode command line tools: `xcode-select --install`
- [ ] iOS Simulator installed
- [ ] Android Studio installed (optional, can use Xcode only)
- [ ] VS Code or Android Studio as IDE
- [ ] Flutter extension installed in IDE

---

## 🚨 If Flutter Installation is Taking Too Long:

**Alternative: Install Flutter manually**

1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/macos
2. Extract to `~/development/flutter`
3. Add to PATH:
```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```
4. Run `flutter doctor` to verify

---

## 📞 Client Communication:

**Send to Andrés now:**

```
Hey Andrés!

Got your $150 - thank you! I'm setting up the development environment now.

Quick question: Do you have a list of the 20 brothers who need accounts? I'll need their emails to set up the invitation system.

Also, what's the current semester you want to track? (e.g., "Spring 2025")
And what's the dues amount and due date?

I'll send you a demo by end of this week showing the login and basic navigation.

Talk soon!
```

---

## ⏰ Time Breakdown (10 hours this week):

| Task | Time | When |
|------|------|------|
| Flutter setup + Supabase | 2 hrs | Today |
| Auth screens UI | 2 hrs | Tomorrow |
| Auth logic + Riverpod | 2 hrs | Day 3 |
| Dashboard screens | 2 hrs | Day 4 |
| Navigation + testing | 2 hrs | Day 5 |

---

## 📝 Notes:

- You have the $150 deposit (Payment 1 of 4)
- Next payment ($150) due at Week 2 demo
- Maintenance agreed: $70/semester
- You keep the app store licenses

---

## ✍️ When Flutter Finishes Installing:

Run this command to check:
```bash
/opt/homebrew/bin/flutter doctor
```

You should see:
```
✓ Flutter (Channel stable, 3.24.x)
✓ Xcode
✓ VS Code or Android Studio
```

Then proceed with "Next Steps" above.

---

**I'll continue preparing the initial code files while Flutter downloads. Check back in 15-30 minutes and we'll initialize the project!**
