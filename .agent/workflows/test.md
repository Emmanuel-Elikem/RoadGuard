---
description: Run tests and verify code quality
---

# Testing Workflow

Follow these steps to run all tests and verify code quality.

## 1. Get Dependencies
// turbo
```bash
flutter pub get
```

## 2. Check Code Formatting
// turbo
```bash
dart format --set-exit-if-changed .
```

If formatting fails, run:
```bash
dart format .
```

## 3. Run Static Analysis
// turbo
```bash
flutter analyze --no-fatal-infos
```

Fix any errors before proceeding. Warnings are acceptable but should be minimized.

## 4. Run Unit Tests
// turbo
```bash
flutter test --coverage
```

## 5. Check Test Coverage
// turbo
```bash
lcov --summary coverage/lcov.info
```

**Coverage targets:**
- Unit tests: 90%+
- Widget tests: 70%+

## 6. Build Debug APK (Optional)
For manual testing:
```bash
flutter build apk --debug
```

APK location: `build/app/outputs/flutter-apk/app-debug.apk`

---

## Quick Test Commands

| Action | Command |
|--------|---------|
| Run all tests | `flutter test` |
| Run single test | `flutter test test/path/to/test.dart` |
| Run with coverage | `flutter test --coverage` |
| Run specific test name | `flutter test --name "test name"` |

## Using Dart MCP for Testing

| Action | Tool |
|--------|------|
| Run tests | `run_tests` |
| Analyze files | `analyze_files` |
| Apply fixes | `dart_fix` |
| Format code | `dart_format` |
