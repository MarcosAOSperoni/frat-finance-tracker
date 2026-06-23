# Flutter Setup Checklist

## Once your Flutter download finishes:

### 1. Extract Flutter (2 minutes)
```bash
cd ~/Downloads
# Assuming the file downloaded as flutter_macos_arm64_3.24.5-stable.zip
unzip flutter_macos_arm64_3.24.5-stable.zip

# Move to development directory
mv flutter ~/development/

# Add to PATH
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Verify Flutter Installation (2 minutes)
```bash
flutter doctor

# Accept Android licenses (if you have Android Studio)
flutter doctor --android-licenses

# You should see:
# ✓ Flutter
# ✓ Xcode
```

### 3. Initialize Our Project (3 minutes)
```bash
cd /Users/marcossperoni/development/GitHub/frat-finance-tracker/frat_finance_tracker

# Initialize Flutter project (this will add necessary files)
flutter create . --org com.fratfinance --platforms=ios,android

# Install all dependencies from pubspec.yaml
flutter pub get
```

### 4. Create .env File (1 minute)
```bash
# Copy the example
cp .env.example .env

# You'll add Supabase credentials here later
# For now, use placeholders:
```

`.env` contents:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
ENV=development
```

### 5. Test Run (2 minutes)
```bash
# Open iOS Simulator
open -a Simulator

# Run the app
flutter run
```

You should see the app launch with a login screen!

---

## ✅ Files I've Already Created:

- `lib/main.dart` - App entry point
- `lib/app/app.dart` - Main app widget
- `lib/app/router.dart` - Navigation routing
- `lib/core/theme/app_theme.dart` - App theme (navy & gold colors)

---

## 🔜 Next Files to Create (After Flutter is set up):

1. Auth provider (Riverpod state management)
2. Supabase client service
3. Login screen UI
4. Signup screen UI
5. Dashboard screens

---

## Estimated Time:
- Download Flutter: 5-15 min (depends on internet)
- Extract & setup: 5 min
- Initialize project: 3 min
- **Total: ~10-25 minutes**

---

**Message me when Flutter is installed and `flutter doctor` passes!**
