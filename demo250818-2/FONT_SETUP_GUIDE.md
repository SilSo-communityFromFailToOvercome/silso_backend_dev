# Font Setup Guide - Fixing Korean Character Display Issue

## Problem
You're getting this error: "Could not find a set of Noto fonts to display all missing characters" when pressing vote buttons. This happens because the app is using 'Pretendard' font family but the font files aren't properly configured.

## Solution 1: Add Pretendard Font Files (Recommended)

### Step 1: Download Pretendard Fonts
1. Go to: https://github.com/orioncactus/pretendard/releases
2. Download the latest release (Pretendard-2.x.x.zip)
3. Extract the zip file

### Step 2: Copy Font Files
Copy these font files from the extracted folder to `assets/fonts/`:
```
- Pretendard-Regular.otf (or .ttf)
- Pretendard-Medium.otf (or .ttf) 
- Pretendard-SemiBold.otf (or .ttf)
- Pretendard-Bold.otf (or .ttf)
```

### Step 3: Run Flutter Commands
```bash
flutter clean
flutter pub get
flutter run
```

## Solution 2: Use Google Fonts (Easier Alternative)

### Step 1: Add Google Fonts Package
Add to `pubspec.yaml` dependencies:
```yaml
dependencies:
  google_fonts: ^6.1.0
```

### Step 2: Remove Custom Font Configuration
Remove the fonts section from pubspec.yaml (lines 132-142)

### Step 3: Update Text Styles
Replace all instances of:
```dart
fontFamily: 'Pretendard'
```

With:
```dart
fontFamily: GoogleFonts.notoSans().fontFamily
```

Or import and use:
```dart
import 'package:google_fonts/google_fonts.dart';

TextStyle(
  fontFamily: GoogleFonts.notoSansKR().fontFamily,
  // other properties...
)
```

### Step 4: Run Flutter Commands
```bash
flutter clean
flutter pub get
flutter run
```

## Quick Fix (Temporary)
If you want a quick temporary fix, you can also:

1. Remove the font family references entirely by commenting out all `fontFamily: 'Pretendard'` lines
2. This will use the system default font which supports Korean characters

## Recommended Solution
**Solution 1** is recommended as Pretendard is designed specifically for Korean text and provides better readability and consistency.

## Verification
After implementing either solution, test by:
1. Running the app
2. Going to the community page
3. Pressing the vote button
4. The Korean text should display properly without font errors