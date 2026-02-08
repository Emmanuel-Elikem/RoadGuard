# RoadGuard - Antigravity Agent Rules

> **Project:** RoadGuard - Road Safety App for Ghana  
> **Target User:** PASSENGERS (not drivers) monitoring speed and rating drivers

---

## 🎯 Quick Reference

| Attribute | Value |
|-----------|-------|
| **Framework** | Flutter 3.38.x, Dart 3.10.x |
| **State** | Riverpod 3.x |
| **Storage** | Hive (local), Firebase (cloud) |
| **Navigation** | go_router |
| **Architecture** | Clean Architecture + Offline-First |

---

## 🚨 Critical Rules

### 1. OFFLINE-FIRST (Non-Negotiable)
Every feature MUST work without internet. Save to Hive first, then queue for Firebase sync.

### 2. NO HARDCODED VALUES
```dart
// ❌ NEVER
color: Color(0xFF1A1A2E)
fontSize: 24

// ✅ ALWAYS
color: AppColors.background
style: AppTypography.headlineMedium
```

### 3. FILE NAMING
All lowercase with underscores: `speed_tracker_service.dart`

### 4. ERROR HANDLING
Always wrap async operations in try-catch, return `Result<T>` types.

### 5. RIVERPOD USAGE
- `ref.watch()` in `build()` method
- `ref.read()` in callbacks only

### 6. TEST EVERYTHING (Non-Negotiable)
**After writing ANY function or feature:**
1. Run `flutter analyze && flutter test`
2. Consider Ghana-specific edge cases (see table below)
3. Manual test on physical device before declaring complete
4. Get user confirmation before moving to next feature

> **🚨 NEVER move to next feature until current feature is tested and verified!**

---

## 📚 Detailed Documentation

For comprehensive guidelines, see `.github/agents/`:

| Topic | File |
|-------|------|
| Coding Standards | [RoadGuard-Coding-Standards.md](.github/agents/RoadGuard-Coding-Standards.md) |
| Design System | [RoadGuard-Design-System.md](.github/agents/RoadGuard-Design-System.md) |
| Backend Logic | [RoadGuard-Backend-Logic.md](.github/agents/RoadGuard-Backend-Logic.md) |
| MVP Plan | [RoadGuard-MVP-Plan.md](.github/agents/RoadGuard-MVP-Plan.md) |
| Mistakes Log | [RoadGuard-Mistakes-Log.md](.github/agents/RoadGuard-Mistakes-Log.md) |
| Database Schema | [RoadGuard-Database-Schema.md](.github/agents/RoadGuard-Database-Schema.md) |
| Algorithms | [RoadGuard-Algorithms.md](.github/agents/RoadGuard-Algorithms.md) |

---

## 🇬🇭 Ghana Edge Cases (ALWAYS Consider)

| Scenario | Why It Matters | Test Approach |
|----------|---------------|---------------|
| Poor GPS in trotro | Dense traffic, tall buildings | Test with accuracy > 50m |
| Heavy rain | Weather affects GPS | Simulate poor accuracy |
| Rough roads | Speed jitter from potholes | Test rapid speed changes |
| Slow phones | Budget phones common | Test with throttled CPU |
| No internet | Common in rural Ghana | Test full offline mode |
| Dusty plates | Hard to read with OCR | Test degraded image quality |
| Battery saver | OS kills background apps | Test after 5+ mins background |

---

## ✅ Pre-Task Checklist

Before starting ANY task:
1. Check [Mistakes Log](.github/agents/RoadGuard-Mistakes-Log.md) for known issues
2. Check [Design System](.github/agents/RoadGuard-Design-System.md) for UI work
3. Follow [Coding Standards](.github/agents/RoadGuard-Coding-Standards.md) for all code
4. **Review Ghana Edge Cases table above**

---

## ✅ Post-Task Checklist

After completing ANY task:
- [ ] `flutter analyze` passes with no issues
- [ ] `flutter test` passes (MUST run before declaring complete)
- [ ] **Ghana edge cases considered and tested**
- [ ] Works offline (test with airplane mode)
- [ ] Light AND dark mode tested
- [ ] No hardcoded values (grep for `Colors.white`, `Colors.black`)
- [ ] Manual test on physical device
- [ ] Mistakes logged if any found
- [ ] **User confirmation received before next feature**

---

## 🌿 Git Workflow

| Type | Branch Pattern | Example |
|------|----------------|---------|
| Feature | `feature/<description>` | `feature/speed-tracker-ui` |
| Bug Fix | `bugfix/<description>` | `bugfix/gps-accuracy-issue` |
| Hotfix | `hotfix/<description>` | `hotfix/crash-on-launch` |

**Commit Format:** `feat:`, `fix:`, `docs:`, `refactor:`, `test:`

---

## 🔧 Available Workflows

Use these workflows for common tasks:
- `/develop` - Start new feature development
- `/pull-request` - Create PR with Copilot review
- `/test` - Run all tests
- `/debug` - Debug app issues

---

## 🤖 Copilot Review Rules (ALWAYS FOLLOW)

### After Fixing Copilot Comments:
> **⚠️ ALWAYS re-request Copilot review after pushing fixes!**  
> Copilot often finds additional issues on subsequent reviews.

1. Push fixes
2. Request Copilot review again
3. Repeat until no more comments

### Async Workflow (Continue While Reviewing):
1. Merge PR when core functionality works
2. Create new branch for next week
3. If Copilot reviews merged code, create small fix PRs
4. Keep new branch rebased on main

---

## 📌 Future Considerations

Track deferred decisions in GitHub Issues with `[FUTURE]` prefix.

| Issue | Description | When to Revisit |
|-------|-------------|-----------------|
| [#5](https://github.com/Emmanuel-Elikem/RoadGuard/issues/5) | Phase 3: Sensor Fusion UI | After vehicle testing |

> **Check these issues before major releases or when related features change!**
