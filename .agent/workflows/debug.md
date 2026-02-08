---
description: Structured debugging for RoadGuard errors
---

# Debug Analysis Workflow

Use this structured approach when debugging errors in RoadGuard.

## Prerequisites
Gather this information before debugging:
- Error message/stack trace
- What you were doing when the error occurred
- Relevant code files

---

## Step 1: Error Classification

Classify the error type:

| Type | Examples | Common Fix |
|------|----------|------------|
| Build Error | `Target URI doesn't exist`, `undefined name` | Check imports, file names |
| Runtime Error | `Null check operator`, `setState after dispose` | Check null safety, lifecycle |
| Firebase Error | `No Firebase App`, `permission denied` | Check init, auth state |
| Location Error | `Permission denied`, `Location disabled` | Check permissions |
| Hive Error | `Box not open`, `Adapter not registered` | Check init order |

---

## Step 2: Generate Predictions

List 3-5 possible causes based on error type:

1. **Prediction 1:** [Most likely cause based on error message]
2. **Prediction 2:** [Alternative cause]
3. **Prediction 3:** [Less common but possible]

---

## Step 3: Investigate Code

For each prediction, check:

- [ ] Does the symptom match this prediction?
- [ ] Is there code evidence supporting this?
- [ ] Has this area changed recently?

**Use these tools:**
- `get_runtime_errors` - View recent exceptions
- `get_app_logs` - Check console output
- `get_widget_tree` - Inspect UI state
- `flutter analyze` - Static analysis

---

## Step 4: Identify Root Cause

After investigation, select the most likely cause:

**Root Cause:** [Description]

**Evidence:**
- [Code reference 1]
- [Code reference 2]

**Related Mistakes:** Check if this is in [Mistakes Log](.github/agents/RoadGuard-Mistakes-Log.md)

---

## Step 5: Implement Fix

1. Apply the fix
2. Run `flutter analyze`
3. Run `flutter test`
4. Hot reload/restart to verify

---

## Step 6: Log the Mistake

If this is a new error pattern, add to `.github/agents/RoadGuard-Mistakes-Log.md`:

```markdown
#### MXXX: [Brief Title]
**Status:** 🟢 Resolved  
**Severity:** [Critical/High/Medium/Low]
**Date:** YYYY-MM-DD

**Symptom:**
[Error message]

**Cause:**
[Root cause]

**Prevention:**
[How to avoid]

**Fix:**
[Solution applied]
```

---

## Common RoadGuard Errors Quick Reference

### Firebase Not Initialized
```
No Firebase App '[DEFAULT]' has been created
```
**Fix:** Ensure `await Firebase.initializeApp()` in `main()` before `runApp()`

### Hive Box Not Open
```
HiveError: The box "trips" is not open
```
**Fix:** Check adapter registration order and box opening in `main.dart`

### setState After Dispose
```
setState() called after dispose()
```
**Fix:** Add `if (!mounted) return;` before setState, or use Riverpod

### Location Permission Denied
```
Location permission denied
```
**Fix:** Check `PermissionService` flow and `permission_handler` setup

### ref.read in build()
```
UI not updating when state changes
```
**Fix:** Use `ref.watch()` in build method, `ref.read()` only in callbacks
