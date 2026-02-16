# RoadGuard UX Copy Guide

> **MANDATORY REFERENCE** — Every user-facing string in RoadGuard MUST follow this guide. No exceptions.

---

## 📋 Table of Contents

1. [The RoadGuard Voice](#the-roadguard-voice)
2. [Golden Rules](#golden-rules)
3. [Word Swap Table](#word-swap-table)
4. [Full Translation Table](#full-translation-table)
5. [Writing New UI Text](#writing-new-ui-text)
6. [Error Message Patterns](#error-message-patterns)
7. [Checklist](#checklist)

---

## 🗣️ The RoadGuard Voice

RoadGuard speaks like a **calm, helpful friend** — not a computer.

| Trait | Description | Example |
|-------|-------------|---------|
| **Simple** | Plain English, short sentences | "Weak signal" not "GPS_ACCURACY_LOW" |
| **Friendly** | Warm but not chatty | "We need location access" not "PERMISSION REQUIRED" |
| **Action-oriented** | Tell users what to DO | "Move to open area" not "Signal lost" alone |
| **Honest** | Don't hide problems, but don't panic | "Speed may vary" not "DATA UNRELIABLE" |
| **Ghana-aware** | Local context, local language level | "Car number" not "License plate registration" |

### Target Audience
**Passengers** in Ghana — taxis, trotros, buses. Mix of tech-savvy and first-time smartphone users. English is official but keep it simple.

---

## 🔒 Golden Rules

### 1. No Technical Jargon
```
❌ "GPS signal weak (accuracy: ±25m)"
✅ "Weak signal — speed may vary"

❌ "Sync failed. Retry in 30s"
✅ "Couldn't save online. We'll try again"

❌ "Permission denied: ACCESS_FINE_LOCATION"
✅ "We need location access to check your speed"
```

### 2. Never Expose Raw Errors
```dart
// ❌ NEVER
'Error: $e'
'Failed: ${error.toString()}'
'GPS Error: $e'

// ✅ ALWAYS
'Something went wrong. Please try again.'
'Location lost — check your settings'
'Couldn\'t save your trip. Please try again.'
```

### 3. Use "You/Your" Not "User/Data"
```
❌ "User data will be preserved"
✅ "Your saved data on this phone will be kept"

❌ "Local data synced"
✅ "Your trips have been saved online"
```

### 4. Positive Before Negative
```
❌ "GPS failed. Cannot track speed."
✅ "We're having trouble finding your location. Move to an open area."

❌ "No trips found"
✅ "No trips yet — start one from the home screen!"
```

### 5. Tell Them What to DO
```
❌ "Permission blocked"
✅ "Location access was blocked. Open Settings, find RoadGuard, and turn on Location."

❌ "Signal lost"
✅ "Signal lost. Move to an open area."
```

### 6. No ALL CAPS in Buttons (Except Short Labels)
```
❌ "SAVE TRIP"    → ✅ "Save trip"
❌ "START TRACKING" → ✅ "Start"
✅ "LIVE" (short status badge — OK)
✅ "FASTEST" / "AVERAGE" (stat labels — OK)
```

---

## 🔄 Word Swap Table

> Quick reference: swap these words EVERYWHERE they appear.

| ❌ Don't Say | ✅ Say Instead | Why |
|-------------|---------------|-----|
| GPS | Location / Signal | Technical acronym |
| Tracking | Monitoring / Speed check | Sounds like surveillance |
| Track (verb) | Monitor / Check | Same reason |
| Sync / Syncing | Save online / Saving | Dev jargon |
| Permission | Access | Less formal |
| Grant access | Allow / Turn on | Plain English |
| REC | LIVE | More intuitive |
| Number plate | Car number | Ghana colloquial |
| License plate | Car number | Ghana colloquial |
| TOP SPEED | FASTEST | Friendlier |
| AVG / AVG SPEED | AVERAGE | Don't abbreviate |
| DURATION | TIME | Simpler |
| Speed limit exceeded | Overspeeding! Slow down | Ghana English |
| Offline data | Saved data | Users don't think in "offline" |
| Background tracking | Monitor in background | Less technical |
| Accuracy ±Xm | (hide completely) | Users can't act on this |
| NO GPS | No signal | Plain English |
| Speed tracking | Speed monitoring | Less surveillance-y |
| Plate / Plate number | Car number | Ghana colloquial |
| Query / Fetch | Look up / Find | Dev speak |
| Error / Exception | Something went wrong | Human language |
| Null / Undefined | (never show) | Internal state |

---

## 📊 Full Translation Table

> Every string that needs changing, organized by screen/file.

### Home Screen (`home_screen.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Status bar (active) | "Tracking Active" | "Monitoring speed" |
| Status bar (idle) | "Ready to Track" | "Ready to go" |
| Recording badge | "REC" | "LIVE" |
| Speed warning | "Speed limit exceeded! X km/h > Y km/h" | "Overspeeding! Slow down" |
| Stat card | "DURATION" | "TIME" |
| Stat card | "TOP SPEED" | "FASTEST" |
| Tracking button | "Start Tracking" | "Start" |
| Tracking button | "Stop Tracking" | "Stop" |
| Summary stat | "km total" | "km travelled" |
| Quick action | "Search\nDriver" | "Look Up\nDriver" |
| Quick action | "View\nStats" | "Your\nTrips" |
| Permission button | "Enable Location" | "Turn on location" |
| Permission button | "Grant Permission" | "Allow location access" |

### Speedometer Widget (`speedometer_widget.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| No signal state | "NO GPS" | "No signal" |
| Accuracy display | "±Xm" | Remove entirely (or hide) |

### Settings Screen (`settings_screen.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Subtitle | "App preferences & account" | "Your preferences and account" |
| Section header | "Tracking" | "Speed monitoring" |
| Toggle label | "Background Tracking" | "Monitor in background" |
| Toggle description | "Track speed when app is minimized" | "Keep monitoring when you leave the app" |
| Disable dialog title | "Disable Background Tracking?" | "Stop background monitoring?" |
| Disable dialog body | "Speed tracking will stop when you minimize..." | "Speed monitoring will pause when you leave the app..." |
| Speed limit label | "Speed Limit Warning" | "Speed limit alert" |
| Speed limit desc | "Alert at X km/h" | "You'll be warned above X km/h" |
| Speed alert desc | "Warn when exceeding limit" | "Get notified when going too fast" |
| Slider button | "Default (X)" | "Reset to default (X)" |
| Section header | "Data" | "Your data" |
| Guest subtitle | "Sign in to sync your data" | "Sign in to save your data across devices" |
| Sign in button | "Sign In to Sync Data" | "Sign in to save across devices" |
| Sign in prompt | "Sign in to sync your trips..." | "Sign in to save your trips and ratings across devices." |
| Sign out confirm | "Are you sure? Your local data will be preserved." | "Are you sure? Your saved data on this phone will be kept." |
| Clear confirm | "Trip history cleared" | "All trips have been deleted" |

### Stats Screen (`stats_screen.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Title | "Your Stats" | "Your Trips" |
| Subtitle | "X trip(s) recorded" | "X trip(s) so far" |
| Stat label | "Avg Speed" | "Average speed" |
| Stat label | "Top Speed" | "Fastest speed" |
| Trip detail | "Avg Speed" / "Max Speed" | "Average speed" / "Top speed" |
| Trip plate | "Plate: GR-1234-20" | "Vehicle: GR-1234-20" |
| Trip rating | "Rating: 4/5" | "4 out of 5" |
| Empty state | "Start tracking a trip..." | "Start monitoring a trip from the home screen\nto see your trips here." |

### Rating Screen (`rating_screen.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Error message | "Failed to save trip: $e" | "Couldn't save your trip. Please try again." |
| Save button | "SAVE TRIP" | "Save trip" |
| Stat label | "TOP SPEED" | "FASTEST" |
| Stat label | "AVG SPEED" | "AVERAGE" |

### Permission Service (`permission_service.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Title | "Permission Required" | "Location access needed" |
| Title | "Location Disabled" | "Location is turned off" |
| Title | "Permission Denied" | "Location access declined" |
| Title | "Permission Blocked" | "Location access blocked" |
| Title | "Permission Granted" | "Location access enabled" |
| Title | "Full Access Granted" | "Full location access enabled" |
| Body | "...needs location access to track your speed..." | "...needs to know your location to monitor speed and keep you safe." |
| Body | "Please enable Location Services..." | "Turn on Location in your device settings so RoadGuard can monitor speed." |
| Body | "Location permission is required..." | "RoadGuard needs location access to work. Tap below to allow it." |
| Body | "Location permission was blocked..." | "Location access was blocked. Open your phone's Settings, find RoadGuard, and turn on Location." |
| Body | "Speed tracking works while the app is open..." | "Speed monitoring works while the app is open. To monitor in the background, allow location access 'Always'." |
| Body | "Full location access granted..." | "All set! Speed monitoring works whether the app is open or in the background." |

### Location Service (`location_service.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Signal quality | "GPS" | "Strong signal" |
| Signal quality | "WEAK GPS" | "Weak signal" |
| Signal quality | "POOR GPS" | "Very weak signal" |
| Signal quality | "NO GPS" | "No signal" |

### Background Service (`background_tracking_service.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Channel name | "RoadGuard Tracking" | "RoadGuard Speed Monitor" |
| Notification title | "RoadGuard Service" | "RoadGuard" |
| Notification body | "Initializing..." | "Starting up..." |
| Notification title | "RoadGuard Tracking" | "RoadGuard" |
| Notification body | "Starting GPS..." | "Getting your location..." |
| Notification body | "Speed: X km/h \| ±Ym" | "X km/h" (remove accuracy) |
| Error notification | "RoadGuard Error" + "GPS Error: $e" | "RoadGuard" + "Location lost — check your settings" |

### Tracking Providers (`tracking_providers.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Error | "Failed to start GPS tracking" | "Couldn't start speed monitoring. Please check your location settings." |
| Error | "GPS stream not available" | "Location service is not responding. Try restarting the app." |

### Auth Error Messages (`auth_result.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| invalid-email | "Invalid email address" | "Please enter a valid email address" |
| user-disabled | "This account has been disabled" | "This account has been deactivated. Contact support for help." |
| user-not-found | "No account found with this email" | "We couldn't find an account with that email" |
| wrong-password | "Incorrect password" | "The password you entered is incorrect" |
| invalid-credential | "Invalid email or password" | "The email or password you entered is incorrect" |
| email-already-in-use | "An account already exists with this email" | "This email is already in use. Try signing in instead." |
| google-cancelled | "Google sign in was cancelled" | "Google sign-in was cancelled" |
| google-failed | "Google sign in failed. Please try again" | "Google sign-in didn't work. Please try again." |
| account-exists | "An account already exists...different sign-in method" | "This email is linked to a different sign-in method. Try another way." |
| credential-in-use | "This credential is already linked to another account" | "This sign-in is already connected to another account" |
| requires-recent-login | "Please sign in again to perform this action" | "For security, please sign in again to continue" |
| network-error | "Network error. Check your connection" | "No internet connection. Please check and try again." |
| method-not-enabled | "This sign in method is not enabled" | "This sign-in option is not available right now" |
| unknown | "An unknown error occurred" | "Something went wrong. Please try again." |

### Error App (`error_app.dart`)

| Location | Current Text | New Text |
|----------|-------------|----------|
| Title | "Initialization Failed" | "Something went wrong" |
| Body | "RoadGuard could not start due to an initialization error." | "RoadGuard couldn't start. Please try again or reinstall the app." |
| Error detail | `error.toString()` (raw error) | Remove or replace with "Technical details have been logged" |

---

## ✍️ Writing New UI Text

### Before Writing Any User-Facing String:

1. **Check the Word Swap Table** — is there a word you should avoid?
2. **Read it out loud** — would a trotro passenger understand?
3. **Is there an action?** — tell them what to DO, not just what happened
4. **Is it short?** — under 60 characters for toasts/snackbars
5. **Does it expose internals?** — no error codes, no raw exceptions, no dev terms

### Templates

**Toast / Snackbar:**
```
[What happened]. [What to do].
"Overspeeding! Slow down."
"Couldn't save online. We'll try again."
```

**Permission Request:**
```
RoadGuard needs [what] to [why in user benefit terms].
"RoadGuard needs location access to monitor your speed."
```

**Error:**
```
[What went wrong in plain English]. [Recovery action].
"Couldn't start speed monitoring. Check your location settings."
```

**Empty State:**
```
[Friendly acknowledgment]. [How to fix it].
"No trips yet — start one from the home screen!"
```

**Confirmation Dialog:**
```
Title: [Action question]?
Body: [Consequence in plain language].
Actions: [Gentle option] / [Strong option]
```

### String Constants Rule
All user-facing strings should eventually be moved to a centralized `strings.dart` constants file for:
- Easy auditing
- Future i18n/l10n support (Twi, Ga, Ewe)
- Single source of truth

---

## ⚠️ Error Message Patterns

### Severity Levels

| Severity | Pattern | Example |
|----------|---------|---------|
| **Info** | "[What happened]." | "Your trips have been saved online." |
| **Warning** | "[Problem] — [impact]." | "Weak signal — speed may vary." |
| **Error** | "[What went wrong]. [What to do]." | "Couldn't save your trip. Please try again." |
| **Critical** | "[Serious problem]. [Clear recovery steps]." | "RoadGuard couldn't start. Please try again or reinstall the app." |

### GPS Signal Messages

| State | Banner Message | Behavior |
|-------|---------------|----------|
| Acquiring | "Finding your location..." | Pulsing dots, blue |
| Good | (banner hidden) | No interruption |
| Weak | "Weak signal — speed may vary" | Amber, static |
| Poor | "Poor signal — speed not reliable" | Red, static |
| Lost | "Signal lost. Move to open area" | Red, pulsing |

### Speed Alert Message
```
Trigger: speed > user's limit (default 50 km/h)
Toast: "Overspeeding! Slow down"
Haptic: Heavy impact
Duration: 3 seconds
Color: Error red
```

---

## ✅ Checklist

Before submitting ANY code with user-facing text:

- [ ] No technical jargon (GPS, sync, permission, tracking, etc.)
- [ ] No raw error objects (`$e`, `error.toString()`)
- [ ] No ALL CAPS buttons (except short status labels)
- [ ] Uses "you/your" language
- [ ] Tells user what to DO (not just what happened)
- [ ] Under 60 chars for toasts/snackbars
- [ ] Checked against Word Swap Table
- [ ] Would a first-time smartphone user understand it?
- [ ] Works for both light and dark themes (text contrast)

---

**Document Version:** 1.0
**Created:** February 2026
**Status:** Active — update when new screens/features are added
