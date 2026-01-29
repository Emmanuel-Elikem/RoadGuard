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

## 📊 Issue Statistics

| Severity | Pre-Populated | Active | Resolved |
|----------|---------------|--------|----------|
| 🔴 Critical | 4 | 0 | 0 |
| 🟠 High | 4 | 0 | 0 |
| 🟡 Medium | 4 | 0 | 0 |
| 🟢 Low | 2 | 0 | 0 |
| **Total** | **14** | **0** | **0** |

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
