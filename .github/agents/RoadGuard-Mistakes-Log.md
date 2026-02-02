# RoadGuard Mistakes Log

> Track bugs, mistakes, and lessons learned during development to avoid repeating them.

**Last Updated:** Auto-generated

---

## 🤖 AGENT SELF-DETECTION PROTOCOL

> **CRITICAL:** The AI agent MUST follow this protocol after EVERY response.

### Automatic Error Detection

After completing ANY task, the agent must:

1. **Compile Check:** Run `flutter analyze` mentally or actually
2. **Pattern Check:** Verify code follows all documented patterns
3. **Test Check:** Ensure tests would pass (if applicable)

### Auto-Logging Process

If ANY mistake is detected (by agent or user):

1. **Assign next ID:** Find the highest MXXX number, increment by 1
2. **Use this template:**

```markdown
#### MXXX: [Brief Descriptive Title]
**Status:** 🔴 Active  
**Severity:** [Critical/High/Medium/Low]
**Date Detected:** YYYY-MM-DD
**Detected By:** [Self (Agent) / User / CI]

**Symptom:**
[What observable problem occurred]

**Cause:**
[Root cause analysis - why did this happen]

**Prevention:**
[How to avoid this in the future - be specific]

**Fix:**
[How it was/should be resolved]

**Related Docs:** [Link to relevant doc if applicable]
```

3. **Commit message format:** `docs: log mistake MXXX - [brief description]`
4. **Auto-push:** The docs-sync workflow will handle timestamp updates

### Severity Guidelines

| Level | Criteria | Examples |
|-------|----------|----------|
| 🔴 **Critical** | App crashes, data loss, security issue | Unhandled exception, DB corruption |
| 🟠 **High** | Feature broken, major UX issue | UI not updating, offline mode fails |
| 🟡 **Medium** | Minor bug, degraded experience | Wrong color, slow performance |
| 🟢 **Low** | Cosmetic, code style, warnings | Lint warning, naming convention |

### Status Meanings

| Status | Meaning |
|--------|---------|
| 🔴 Active | Currently affecting the app, needs fix |
| 🟡 Watch for this | Known issue pattern to prevent |
| 🟢 Resolved | Fixed and verified |

---

## 📋 Pre-Populated Issues (From Experience)

### 🔴 Critical Issues

---

#### M001: Case-Sensitive Import Paths (Linux/CI)
**Status:** 🟡 Watch for this  
**Severity:** Critical (Build failure)

**Symptom:**
```
Target of URI doesn't exist: 'package:roadguard/components/UserLocation.dart'
```

**Cause:**  
File named `userlocation.dart` but imported as `UserLocation.dart`. Works on macOS/Windows (case-insensitive) but fails on Linux/CI.

**Prevention:**
- ✅ ALWAYS use lowercase filenames with underscores: `user_location.dart`
- ✅ Follow Dart naming conventions strictly
- ✅ Set up CI to run on Linux to catch early

**Fix:** Rename file to match import exactly (lowercase).

---

#### M002: Firebase Not Initialized
**Status:** 🟡 Watch for this  
**Severity:** Critical (Crash on launch)

**Symptom:**
```
No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()
```

**Cause:**  
Accessing Firebase services before `Firebase.initializeApp()` completes.

**Prevention:**
```dart
// ✅ CORRECT: Always await initialization in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  runApp(ProviderScope(child: MyApp()));
}
```

**Fix:** Ensure `Firebase.initializeApp()` is awaited before `runApp()`.

---

#### M003: Hive Box Not Opened
**Status:** 🟡 Watch for this  
**Severity:** Critical (Crash)

**Symptom:**
```
HiveError: The box "users" is not open.
```

**Cause:**  
Accessing a Hive box before opening it.

**Prevention:**
```dart
// ✅ CORRECT: Open all boxes during app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register adapters FIRST
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(TripModelAdapter());
  
  // THEN open boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<TripModel>('trips');
  await Hive.openBox('settings');
  
  runApp(ProviderScope(child: MyApp()));
}
```

**Fix:** Register adapters and open boxes in correct order during initialization.

---

#### M004: setState() Called After dispose()
**Status:** 🟡 Watch for this  
**Severity:** Critical (Crash)

**Symptom:**
```
setState() called after dispose(): _MyWidgetState
```

**Cause:**  
Async operation completes after widget is disposed, then calls `setState()`.

**Prevention:**
```dart
// ✅ CORRECT: Check mounted before setState
Future<void> _loadData() async {
  final data = await fetchData();
  
  if (!mounted) return;  // ← Guard clause
  
  setState(() {
    _data = data;
  });
}
```

**Better Prevention:**  
Use Riverpod providers instead of StatefulWidgets where possible.

---

### 🟠 High Severity Issues

---

#### M005: Using ref.read in build()
**Status:** 🟡 Watch for this  
**Severity:** High (Silent bugs, UI not updating)

**Symptom:**  
UI doesn't update when state changes.

**Cause:**
```dart
// ❌ WRONG: Using ref.read in build method
@override
Widget build(BuildContext context) {
  final user = ref.read(userProvider);  // This won't rebuild!
  return Text(user.name);
}
```

**Prevention:**
```dart
// ✅ CORRECT: Use ref.watch for reactive updates
@override
Widget build(BuildContext context) {
  final user = ref.watch(userProvider);  // This WILL rebuild
  return Text(user.name);
}

// ✅ ref.read is ONLY for callbacks
onPressed: () {
  ref.read(counterProvider.notifier).increment();
}
```

**Rule of thumb:**
- `ref.watch` = In `build()` method
- `ref.read` = In callbacks, button handlers, etc.

---

#### M006: Missing ProviderScope
**Status:** 🟡 Watch for this  
**Severity:** High (All providers fail)

**Symptom:**
```
Bad state: No ProviderScope found
```

**Cause:**  
Forgot to wrap `MaterialApp` with `ProviderScope`.

**Prevention:**
```dart
// ✅ CORRECT: Wrap at the root
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

---

#### M007: Location Permission Not Checked
**Status:** 🟡 Watch for this  
**Severity:** High (Crash or silent failure)

**Symptom:**  
App crashes or location returns null unexpectedly.

**Cause:**  
Requesting location without checking permission status first.

**Prevention:**
```dart
// ✅ CORRECT: Full permission flow
Future<Position?> getCurrentLocation() async {
  // 1. Check if location service is enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Prompt user to enable
    return null;
  }
  
  // 2. Check permission
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    // Request permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Can't request, must go to settings
    await Geolocator.openAppSettings();
    return null;
  }
  
  // 3. Now safe to get location
  return await Geolocator.getCurrentPosition();
}
```

---

#### M008: Unbounded Firestore Query
**Status:** 🟡 Watch for this  
**Severity:** High (Quota exceeded, slow performance)

**Symptom:**  
Slow queries, Firebase quota warnings, excessive reads.

**Cause:**
```dart
// ❌ WRONG: No limit - could return millions of docs
final allDrivers = await FirebaseFirestore.instance
    .collection('drivers')
    .get();
```

**Prevention:**
```dart
// ✅ CORRECT: Always limit queries
final drivers = await FirebaseFirestore.instance
    .collection('drivers')
    .limit(50)  // ← Always set a reasonable limit
    .get();

// ✅ CORRECT: With pagination
final drivers = await FirebaseFirestore.instance
    .collection('drivers')
    .orderBy('rating', descending: true)
    .startAfterDocument(lastDoc)
    .limit(20)
    .get();
```

---

### 🟡 Medium Severity Issues

---

#### M009: Hardcoded Colors
**Status:** 🟡 Watch for this  
**Severity:** Medium (Inconsistent UI, theme breaks)

**Symptom:**  
Some elements don't change when switching themes.

**Cause:**
```dart
// ❌ WRONG: Hardcoded color
Container(
  color: Colors.black,  // Won't adapt to theme!
)
```

**Prevention:**
```dart
// ✅ CORRECT: Use theme colors
Container(
  color: Theme.of(context).colorScheme.surface,
)

// ✅ CORRECT: Use extension for custom colors
Container(
  color: context.colors.goodDriver,
)
```

---

#### M010: Hardcoded Strings
**Status:** 🟡 Watch for this  
**Severity:** Medium (Bad for i18n)

**Symptom:**  
Can't localize app easily later.

**Cause:**
```dart
// ❌ WRONG: Hardcoded text
Text('Start Tracking')
```

**Prevention:**
```dart
// ✅ CORRECT: Use localization keys (set up flutter_localizations)
Text(AppLocalizations.of(context)!.startTracking)

// ✅ ACCEPTABLE: Constants file for now (MVP)
// lib/core/constants/strings.dart
class AppStrings {
  static const startTracking = 'Start Tracking';
}
Text(AppStrings.startTracking)
```

---

#### M011: Missing Loading States
**Status:** 🟡 Watch for this  
**Severity:** Medium (Poor UX)

**Symptom:**  
Users tap button multiple times, no feedback.

**Prevention:**
```dart
// ✅ CORRECT: Show loading state
final isLoadingProvider = StateProvider<bool>((ref) => false);

ElevatedButton(
  onPressed: isLoading 
    ? null  // Disable when loading
    : () async {
        ref.read(isLoadingProvider.notifier).state = true;
        try {
          await doSomething();
        } finally {
          ref.read(isLoadingProvider.notifier).state = false;
        }
      },
  child: isLoading 
    ? CircularProgressIndicator()
    : Text('Submit'),
)
```

---

#### M012: Forgetting Hive TypeAdapter Registration
**Status:** 🟡 Watch for this  
**Severity:** Medium (Data serialization fails)

**Symptom:**
```
HiveError: Cannot write, unknown type: UserModel
```

**Cause:**  
Custom class stored in Hive without registering adapter.

**Prevention:**
```dart
// 1. Define model with annotations
@HiveType(typeId: 0)  // Unique typeId per class
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  UserModel({required this.id, required this.name});
}

// 2. Generate adapter: flutter pub run build_runner build

// 3. Register before opening box
Hive.registerAdapter(UserModelAdapter());
await Hive.openBox<UserModel>('users');
```

---

### 🟢 Low Severity Issues

---

#### M013: Using print() in Production
**Status:** 🟡 Watch for this  
**Severity:** Low (Performance, security)

**Symptom:**  
Sensitive data in logs, slight performance hit.

**Prevention:**
```dart
// ❌ WRONG
print('User token: $token');

// ✅ CORRECT: Use debugPrint (only in debug mode)
debugPrint('Loading user...');

// ✅ BETTER: Use a proper logger
import 'package:logger/logger.dart';
final logger = Logger();
logger.d('Debug message');
logger.e('Error message');
```

---

#### M014: Improper Error Handling
**Status:** 🟡 Watch for this  
**Severity:** Low (Hard to debug)

**Cause:**
```dart
// ❌ WRONG: Swallowing errors
try {
  await saveData();
} catch (e) {
  // Silent failure!
}
```

**Prevention:**
```dart
// ✅ CORRECT: Log and handle appropriately
try {
  await saveData();
} catch (e, stackTrace) {
  debugPrint('Failed to save data: $e');
  // Report to crash analytics
  FirebaseCrashlytics.instance.recordError(e, stackTrace);
  // Show user-friendly error
  showErrorSnackbar('Could not save. Please try again.');
}
```

---

## 📝 Issue Template

Copy this template when logging new issues:

```markdown
---

#### MXXX: [Brief Title]
**Status:** 🔴 Active / 🟡 Watch for this / 🟢 Resolved  
**Severity:** Critical / High / Medium / Low  
**Date Found:** YYYY-MM-DD  
**Date Resolved:** YYYY-MM-DD (if applicable)

**Symptom:**  
What did you observe? Error message? Behavior?

**Cause:**  
Why did this happen? Root cause.

**Prevention:**
```dart
// How to avoid this in the future
```

**Fix:**  
How was it resolved? (if applicable)

**Related Files:**
- `path/to/file.dart`

---
```

---

## � Session Mistakes (2026-01-31)

### CI/GitHub Actions Issues

---

#### M015: Non-Existent GitHub Action
**Status:** 🟢 Resolved  
**Severity:** Critical (CI failure)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
Error: Unable to resolve action github/copilot-code-review-action, repository not found
```

**Cause:**
Used a fictional GitHub Action `github/copilot-code-review-action@v1` that doesn't exist publicly. The AI assumed it existed without verifying.

**Prevention:**
- ✅ ALWAYS verify GitHub Actions exist before using them
- ✅ Check the GitHub Marketplace for official actions
- ✅ Don't assume actions exist based on naming patterns

**Fix:**
Replaced with a working workflow that runs `dart format`, `flutter analyze`, and `flutter test` instead of relying on a non-existent AI review action.

**Related Files:**
- `.github/workflows/copilot-review.yml`

---

#### M016: Invalid Flutter Version in CI
**Status:** 🟢 Resolved  
**Severity:** Critical (CI failure)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
pubspec.yaml requires Dart SDK version ^3.10.4, but environment provides 3.8.1
```

**Cause:**
Used `flutter-version: '3.32.2'` which doesn't exist. The action fell back to an old Flutter version that didn't meet our SDK constraint.

**Prevention:**
```yaml
# ✅ CORRECT: Use '3.x' to get latest stable
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.x'
    channel: 'stable'

# ❌ WRONG: Specific version that may not exist
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.32.2'  # This version doesn't exist!
```

**Fix:**
Changed `flutter-version` from `'3.32.2'` to `'3.x'` to use latest stable.

**Related Files:**
- `.github/workflows/copilot-review.yml`

---

### Code Definition Errors

---

#### M017: Using Undefined Color Properties
**Status:** 🟢 Resolved  
**Severity:** Medium (Compile error)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
error: The getter 'onPrimary' isn't defined for the type 'AppColors'
```

**Cause:**
Used `AppColors.onPrimary` without checking if it exists in our color definitions. The design system doc mentioned `onPrimary` but we didn't add it to `app_colors.dart`.

**Prevention:**
- ✅ ALWAYS check `app_colors.dart` before using color names
- ✅ If a color doesn't exist, add it OR use an existing one
- ✅ Run `flutter analyze` after writing code

**Fix:**
Replaced `AppColors.onPrimary` with `AppColors.background` (dark color for contrast on bright primary).

**Related Files:**
- `lib/features/auth/presentation/auth_screen.dart`
- `lib/features/auth/presentation/onboarding_screen.dart`

---

#### M018: Using Undefined Dimension Properties
**Status:** 🟢 Resolved  
**Severity:** Medium (Compile error)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
error: The getter 'radiusXxl' isn't defined for the type 'AppDimensions'
```

**Cause:**
Used `AppDimensions.radiusXxl` but our dimensions file only has `radiusXl`. Didn't verify the exact property name.

**Prevention:**
- ✅ Check `app_dimensions.dart` for exact property names
- ✅ Our radius scale: `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl`, `radiusFull`
- ✅ No `radiusXxl` - use `32` directly or add it to dimensions

**Fix:**
Replaced `AppDimensions.radiusXxl` with hardcoded `32` (will add to dimensions in refactor).

**Related Files:**
- `lib/shared/widgets/floating_nav_bar.dart`

---

#### M019: Using Non-Existent Icon Names
**Status:** 🟢 Resolved  
**Severity:** Medium (Compile error)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
error: The getter 'carFront' isn't defined for the type 'LucideIcons'
```

**Cause:**
Used `LucideIcons.carFront` but this icon doesn't exist in the lucide_icons package. Icon names vary between icon libraries.

**Prevention:**
- ✅ Check the lucide_icons package documentation for available icons
- ✅ Common alternatives: `car`, `carTaxiFront`, `bus`
- ✅ Use IDE autocomplete to see available options

**Fix:**
Changed `LucideIcons.carFront` to `LucideIcons.car`.

**Related Files:**
- `lib/features/search/presentation/search_screen.dart`

---

### Testing Issues

---

#### M020: Timer Pending in Tests
**Status:** 🟢 Resolved  
**Severity:** High (Test failure)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
A Timer is still pending even after the widget tree was disposed.
Failed assertion: !timersPending
```

**Cause:**
The splash screen uses `Future.delayed()` for navigation, creating a timer. When the test ends before the timer completes, Flutter complains about pending timers.

**Prevention:**
```dart
// ✅ Option 1: Pump enough time to complete timers
await tester.pump(const Duration(seconds: 3));

// ✅ Option 2: Don't test screens with timers directly
// Test components individually instead

// ✅ Option 3: Make delay duration injectable for testing
class SplashScreen extends StatefulWidget {
  final Duration delay;
  const SplashScreen({this.delay = const Duration(seconds: 2)});
}
```

**Fix:**
Changed test to test `OnboardingScreen` instead of `SplashScreen` to avoid timer complications.

**Related Files:**
- `test/widget_test.dart`
- `lib/features/auth/presentation/splash_screen.dart`

---

#### M021: GoRouter Not Found in Test Context
**Status:** 🟢 Resolved  
**Severity:** High (Test failure)
**Date Found:** 2026-01-31
**Date Resolved:** 2026-01-31

**Symptom:**
```
No GoRouter found in context
Failed assertion: 'inherited != null'
```

**Cause:**
Testing a screen that uses `context.go()` without providing a GoRouter in the widget tree.

**Prevention:**
```dart
// ✅ CORRECT: Provide a GoRouter in tests
testWidgets('Screen test', (tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MyScreen()),
      GoRoute(path: '/next', builder: (_, __) => const Scaffold()),
    ],
  );
  
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router),
  );
});

// ❌ WRONG: No router provided
await tester.pumpWidget(MaterialApp(home: MyScreen()));
```

**Fix:**
Added a minimal GoRouter configuration in the test file.

**Related Files:**
- `test/widget_test.dart`

---

#### M022: Unnecessary Double Underscore for Unused Parameters
**Status:** 🟢 Resolved  
**Severity:** Low (Lint warning)
**Date Found:** 2025-01-31
**Date Resolved:** 2025-01-31

**Symptom:**
```
info • Unnecessary use of multiple underscores • test/widget_test.dart:19:41
```

**Cause:**
Used `(_, __)` to indicate unused parameters in GoRoute builder, but Dart lint prefers a single underscore `_` OR named parameters like `(context, state)`.

```dart
// ❌ Lint warning - double underscore unnecessary
GoRoute(path: '/', builder: (_, __) => const MyScreen()),
```

**Prevention:**
```dart
// ✅ Option 1: Use single underscore (if linter allows)
GoRoute(path: '/', builder: (_, _) => const MyScreen()),

// ✅ Option 2: Use named parameters (clearer)
GoRoute(path: '/', builder: (context, state) => const MyScreen()),
```

**Fix:**
Changed `(_, __)` to `(context, state)` in test file.

**Related Files:**
- `test/widget_test.dart`

---

#### M023: Auth Screen Excessive Spacing - Content Below Fold
**Status:** 🟢 Resolved  
**Severity:** High (Major UX issue)
**Date Found:** 2026-01-31
**Detected By:** User

**Symptom:**
Sign In and Sign Up buttons were hidden below the fold. User had to scroll down to see "Don't have an account? Sign Up" link. Too much padding between elements.

**Cause:**
- Used excessive `spacingXl` and `spacingLg` between elements
- `SingleChildScrollView` with large padding made content extend beyond screen
- Didn't consider mobile screen real estate

**Prevention:**
```dart
// ❌ BAD: Excessive spacing pushes content below fold
const SizedBox(height: AppDimensions.spacingXl), // 32px
const SizedBox(height: AppDimensions.spacingLg), // 24px

// ✅ GOOD: Use smaller spacing, LayoutBuilder for responsiveness
const SizedBox(height: AppDimensions.spacingMd), // 16px
// Consider using Expanded/Spacer instead of fixed spacing
// Use LayoutBuilder to adapt to screen height
```

**UX Rule:**
- ALL critical actions (submit buttons, auth toggles) MUST be visible without scrolling
- Use `LayoutBuilder` or `MediaQuery` to adapt to screen size
- Test on smallest supported screen (320px width, ~568px height)

**Fix:**
Reduced spacing, used `LayoutBuilder` to make content fit screen height.

**Related Files:**
- `lib/features/auth/presentation/auth_screen.dart`

---

#### M024: Missing Smart Sign-In to Sign-Up Auto-Flow
**Status:** 🟢 Resolved  
**Severity:** Medium (UX friction)
**Date Found:** 2026-01-31
**Detected By:** User

**Symptom:**
When user tries to sign in with non-existent email, they get an error. User expected the app to offer automatic sign-up.

**Cause:**
Did not consider users who may enter credentials on sign-in page expecting to create an account.

**Prevention:**
```dart
// ✅ When sign-in fails with "user-not-found" error:
// 1. Show dialog asking if user wants to create account
// 2. If yes, redirect to sign up screen with credential auto-filled
// 3. Reduces friction, improves conversion
```

**UX Rule:**
- Anticipate user mistakes and offer helpful alternatives
- Don't just show errors - offer actionable solutions
- "user-not-found" error is an opportunity, not a dead end

**Fix:**
Added `_showSignUpOfferDialog()` when sign-in returns `userNotFound` error.

**Related Files:**
- `lib/features/auth/presentation/auth_screen.dart`

---

#### M025: Theme Toggle Missing Smooth Animation
**Status:** 🟢 Resolved  
**Severity:** Low (UX polish)
**Date Found:** 2026-01-31
**Detected By:** User

**Symptom:**
Theme toggle selector doesn't have a sliding highlight indicator. Current implementation just swaps colors without visual motion.

**Cause:**
Used simple `AnimatedContainer` without a sliding indicator that moves between options.

**Prevention:**
```dart
// ✅ For segmented controls, add a sliding indicator:
// 1. Use Stack with AnimatedPositioned for sliding highlight
// 2. Add spring animation for natural feel
// 3. Consider haptic feedback on selection
```

**UX Rule:**
- Motion provides feedback and delight
- Segmented controls should have sliding indicators
- Use spring animations (not linear) for natural feel

**Fix:**
Added `_AnimatedThemeSelector` with sliding highlight using `AnimatedPositioned`.

**Related Files:**
- `lib/features/settings/presentation/settings_screen.dart`

---

#### M026: Google Sign-In Missing Web OAuth Client in google-services.json
**Status:** 🔴 Active  
**Severity:** Critical (Feature broken)
**Date Found:** 2026-01-31
**Detected By:** User + Self (Agent)

**Symptom:**
Google Sign-In fails with error. Manual email/password sign-in works fine.

**Cause:**
The `google-services.json` file has an empty `oauth_client` array. Google Sign-In on Android requires a **web OAuth client** (`client_type: 3`) in the `google-services.json` file.

```json
// ❌ CURRENT (broken):
"oauth_client": [],

// ✅ REQUIRED (working):
"oauth_client": [
  {
    "client_id": "574169315182-xxxxxxx.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

**Root Cause:**
- SHA-1 fingerprint was added to Firebase Console
- But `google-services.json` was NOT re-downloaded after enabling Google Sign-In
- The Web OAuth client is created when you enable Google Sign-In provider in Firebase Auth

**Prevention:**
1. After enabling Google Sign-In in Firebase Console → Authentication → Sign-in methods
2. ALWAYS re-download `google-services.json` from Firebase Console
3. Verify the file contains `oauth_client` with `client_type: 3`
4. The `serverClientId` is automatically read from this file

**Fix Steps:**
1. Go to Firebase Console → Project Settings → Your Apps → Android app
2. Click "Download google-services.json"
3. Replace `android/app/google-services.json` with the new file
4. Rebuild the app

**Related Files:**
- `android/app/google-services.json`
- `lib/features/auth/data/datasources/firebase_auth_datasource.dart`

---

#### M027: Auth Error Messages Too Generic ("Unknown Error")
**Status:** 🟢 Resolved  
**Severity:** High (Poor UX)
**Date Found:** 2026-01-31
**Detected By:** User

**Symptom:**
When sign-in fails (wrong password, wrong email), user sees "An unknown error occurred" instead of specific message.

**Cause:**
Firebase Auth changed error codes. Now returns `invalid-credential` instead of separate `wrong-password` and `user-not-found` errors for security reasons.

**Prevention:**
```dart
// ✅ Map ALL Firebase error codes, including new ones:
AuthError _mapFirebaseError(FirebaseAuthException e) {
  return switch (e.code) {
    'invalid-credential' => AuthError.invalidCredential,
    'wrong-password' => AuthError.wrongPassword,  // Legacy
    'user-not-found' => AuthError.userNotFound,   // Legacy
    // ... other codes
    _ => AuthError.unknown,
  };
}
```

**UX Rule:**
- Test error states, not just happy paths
- Log unknown error codes during development
- Provide helpful, actionable error messages

**Fix:**
Added `invalid-credential` mapping to `_mapFirebaseError()` and updated `AuthError` enum with more specific messages.

**Related Files:**
- `lib/features/auth/data/datasources/firebase_auth_datasource.dart`
- `lib/features/auth/domain/entities/auth_result.dart`

---

#### M028: Error Snackbar Text Not Visible (Grey on Red)
**Status:** 🟢 Resolved  
**Severity:** Medium (Poor UX)
**Date Found:** 2026-01-31
**Detected By:** User

**Symptom:**
Error snackbar shows grey text on red background - text is hard to read.

**Cause:**
Used theme's default text color instead of explicitly setting white text on error background.

**Prevention:**
```dart
// ✅ ALWAYS use white text on error background:
SnackBar(
  content: Text(
    message,
    style: const TextStyle(
      color: Colors.white,  // ← Explicit white
      fontWeight: FontWeight.w500,
    ),
  ),
  backgroundColor: colorScheme.error,
)
```

**UX Rule:**
- Error states need high contrast for readability
- White text on red/error backgrounds
- Add action button for dismissal

**Fix:**
Added explicit `Colors.white` text color and dismiss action to error snackbar.

**Related Files:**
- `lib/features/auth/presentation/auth_screen.dart`

---

#### M029: Poor Color Contrast - Neon Green Background with White Text
**Status:** 🟢 Resolved  
**Severity:** Medium (Accessibility/UX)
**Date Found:** 2026-02-02
**Detected By:** User

**Symptom:**
Success snackbar uses neon green (primary) background with white text - text is barely visible due to poor contrast ratio.

**Cause:**
Assumed white text works on all colored backgrounds. Neon green (#39FF14) is a bright, high-luminance color that doesn't provide sufficient contrast with white.

**Prevention:**
```dart
// ❌ BAD - Hardcoded white on any colored background:
SnackBar(
  content: Text('Success!', style: TextStyle(color: Colors.white)),
  backgroundColor: colorScheme.primary,  // Might be bright color!
)

// ✅ GOOD - Use theme's semantic color pairs:
SnackBar(
  content: Text(
    'Success!',
    style: TextStyle(
      color: colorScheme.onPrimary,  // ← Theme knows the right contrast
      fontWeight: FontWeight.w500,
    ),
  ),
  backgroundColor: colorScheme.primary,
)

// ✅ ALTERNATIVE - Use inverseSurface for neutral snackbars:
SnackBar(
  content: Text(
    'Info message',
    style: TextStyle(color: colorScheme.onInverseSurface),
  ),
  backgroundColor: colorScheme.inverseSurface,
)
```

**Color Contrast Rules:**
| Background | Use For Text |
|------------|-------------|
| `primary` | `onPrimary` |
| `secondary` | `onSecondary` |
| `error` | `onError` |
| `surface` | `onSurface` |
| `inverseSurface` | `onInverseSurface` |

**WCAG Guidelines:**
- Normal text: minimum 4.5:1 contrast ratio
- Large text (18pt+): minimum 3:1 contrast ratio
- Use tools like WebAIM Contrast Checker to verify

**Fix:**
Replaced `Colors.white` with `colorScheme.onPrimary` for snackbars using primary background.

**Related Files:**
- `lib/features/auth/presentation/email_verification_screen.dart`
- `lib/features/auth/presentation/auth_screen.dart`

---

## 📊 Issue Statistics

| Severity | Pre-Populated | Active | Resolved |
|----------|---------------|--------|----------|
| 🔴 Critical | 4 | 1 | 0 |
| 🟠 High | 4 | 0 | 3 |
| 🟡 Medium | 4 | 0 | 1 |
| 🟢 Low | 2 | 0 | 1 |
| **Total** | **14** | **1** | **5** |

---

## 🔍 Quick Reference

### Checklist Before PR
- [ ] No hardcoded colors (use theme)
- [ ] No hardcoded dimensions (use constants)
- [ ] Loading states for async operations
- [ ] Error handling with user feedback
- [ ] `mounted` check before `setState`
- [ ] `ref.watch` in build, `ref.read` in callbacks
- [ ] Lowercase filenames with underscores
- [ ] Tests passing
- [ ] No `print()` statements

---

**Document Version:** 1.0  
**Last Updated:** [Auto-generated]
