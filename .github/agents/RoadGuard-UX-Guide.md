# RoadGuard User Experience Guide

> **MASTER UX DOCUMENT** - Comprehensive guide to ALL user flows, error handling, edge cases, and Ghana-specific UX considerations across the entire app.

**IMPORTANT:** Before implementing ANY feature, review this document and update it with new flows, edge cases, and Ghana-specific considerations.

---

## 📋 Table of Contents

1. [UX Principles](#ux-principles)
2. [Ghana-Specific Considerations](#ghana-specific-considerations)
3. [Authentication UX](#authentication-ux)
4. [Navigation UX](#navigation-ux)
5. [Speed Tracking UX](#speed-tracking-ux)
6. [Driver Rating UX](#driver-rating-ux)
7. [Search UX](#search-ux)
8. [Error Handling Patterns](#error-handling-patterns)
9. [Offline-First UX](#offline-first-ux)
10. [Accessibility](#accessibility)
11. [Testing Checklist](#testing-checklist)

---

## 🎯 UX Principles

### Core Philosophy: "Digital Copilot"
The app should feel like a trusted companion that:
- **Anticipates** user needs
- **Guides** without overwhelming
- **Protects** from mistakes
- **Works** even when things go wrong

### The 5 UX Pillars

| Pillar | Description | Implementation |
|--------|-------------|----------------|
| **1. Offline-First** | Everything works without internet | Hive local storage, sync queue |
| **2. Error Prevention** | Stop problems before they happen | Validation, disabled states, confirmation dialogs |
| **3. Clear Feedback** | User always knows what's happening | Loading states, success/error messages, progress indicators |
| **4. Easy Recovery** | Mistakes are never permanent | Undo, retry, alternative paths |
| **5. Progressive Disclosure** | Don't overwhelm, reveal when needed | Guest mode → full account, basic → advanced features |

---

## 🇬🇭 Ghana-Specific Considerations

### Network Reality
**Assumption:** Internet is unreliable, expensive, and slow in many areas.

| Challenge | Solution |
|-----------|----------|
| Unstable connection | Offline-first with background sync |
| Expensive data | Minimal data transfer, compress images |
| Slow connection | Optimistic UI, don't block on network |
| Frequent disconnects | Automatic retry with exponential backoff |

**UX Pattern:**
```
1. Save action locally immediately
2. Show success to user
3. Queue for sync in background
4. Show subtle "syncing" indicator
5. Only show error if sync fails after retries
```

### Device Diversity
**Reality:** Mix of low-end (2GB RAM) and flagship phones.

| Challenge | Solution |
|-----------|----------|
| Low memory | Lazy loading, dispose resources properly |
| Small screens | Responsive design, minimum 44px touch targets |
| Older Android versions | Test on API 24+, graceful degradation |

### User Behavior Patterns

| Behavior | UX Adaptation |
|----------|---------------|
| Share phones with family | Clear "Sign Out" in settings, no auto-remember passwords |
| Distrust new apps | Guest mode first, explain data usage |
| Prefer simple flows | Minimize steps, avoid technical jargon |
| May not check email often | Auto-detect verification, don't rely on user clicking "check" |
| Expect instant results | Optimistic UI, preload data |

### Language & Communication

| Guideline | Example |
|-----------|---------|
| Simple English | "Sign in" not "Authenticate" |
| Action-oriented | "Save your trip" not "Trip data persisted" |
| Positive framing | "Check your email" not "Email not verified" |
| Local context | Use Ghana plate format (GR-1234-20) |

### Common User Mistakes to Prevent

| Mistake | Prevention |
|---------|------------|
| Entering wrong plate format | Real-time validation, format hints |
| Rating wrong driver | Confirm before submit, show plate clearly |
| Losing data | Auto-save, sync indicators |
| Forgetting password | Google sign-in option, easy reset |

---

## 🔐 Authentication UX

RoadGuard supports three authentication methods:

| Method | Verification Required | Best For |
|--------|----------------------|----------|
| **Email/Password** | ✅ Email verification | Full account features |
| **Google Sign-In** | ❌ Already verified | Quick, trusted sign-in |
| **Guest Mode** | ❌ Anonymous | Try before signing up |

---

## 🔄 Complete Auth Flow Diagrams

### Sign Up Flow (Email)

```
User taps "Sign Up"
    │
    ├─► Validates email format
    │       ├── Empty → "Please enter your email"
    │       └── Invalid → "Please enter a valid email"
    │
    ├─► Validates password
    │       ├── Empty → "Please enter your password"
    │       └── <6 chars → "Password must be at least 6 characters"
    │
    ├─► Firebase creates account
    │       ├── Email in use → "An account already exists with this email"
    │       ├── Weak password → "Password must be at least 6 characters"
    │       ├── Network error → "Network error. Check your connection"
    │       └── Success → Continue
    │
    └─► Redirect to Email Verification Screen
            │
            ├── Auto-sends verification email
            ├── Polls every 3 seconds for verification
            ├── 60-second cooldown on resend
            │
            └── User clicks link in email
                    │
                    └─► Redirect to Home
```

### Sign In Flow (Email)

```
User taps "Sign In"
    │
    ├─► Validates email format
    │       ├── Empty → "Please enter your email"
    │       └── Invalid → "Please enter a valid email"
    │
    ├─► Validates password
    │       └── Empty → "Please enter your password"
    │
    ├─► Firebase authenticates
    │       ├── User not found → Show "Create Account?" dialog
    │       ├── Wrong password → "Invalid email or password"
    │       ├── Too many attempts → "Too many attempts. Please try again later"
    │       ├── Network error → "Network error. Check your connection"
    │       └── Success → Continue
    │
    └─► Check email verification
            ├── Not verified → Redirect to Verification Screen
            └── Verified → Redirect to Home
```

### Google Sign-In Flow

```
User taps "Continue with Google"
    │
    ├─► Google Sign-In prompt opens
    │       ├── User cancels → "Google sign in was cancelled"
    │       └── User selects account → Continue
    │
    ├─► Get Google credentials
    │       └── Failed → "Google sign in failed. Please try again"
    │
    ├─► Firebase authenticates with credentials
    │       ├── Account exists with different method →
    │       │       "An account already exists with this email 
    │       │        using a different sign-in method"
    │       └── Success → Continue
    │
    └─► Redirect to Home (no verification needed - Google emails are verified)
```

### Guest Mode Flow

```
User taps "Continue as Guest"
    │
    ├─► Firebase creates anonymous account
    │       ├── Failed → "An unknown error occurred"
    │       └── Success → Continue
    │
    └─► Redirect to Home
        │
        └── Later: Can upgrade to full account via Settings
            (Links anonymous account to email/Google)
```

### Password Reset Flow

```
User taps "Forgot password?"
    │
    └─► Password Reset Screen
            │
            ├─► Enter email
            │       ├── Empty → "Please enter your email"
            │       └── Invalid → "Please enter a valid email"
            │
            ├─► Firebase sends reset email
            │       ├── Network error → "Network error. Check your connection"
            │       └── Success → Show success state
            │           (Note: Firebase always shows success even if
            │            email doesn't exist - security best practice)
            │
            └─► User clicks link in email
                    │
                    └── Firebase password reset page
                            │
                            └── Return to app and sign in with new password
```

---

## 🚨 Error Message Reference

### Form Validation Errors (Client-side)

| Condition | Message |
|-----------|---------|
| Empty email | "Please enter your email" |
| Invalid email format | "Please enter a valid email" |
| Empty password | "Please enter your password" |
| Password < 6 chars (signup) | "Password must be at least 6 characters" |

### Firebase Auth Errors (Server-side)

| Error Code | User Message | When |
|------------|--------------|------|
| `invalid-email` | "Invalid email address" | Malformed email |
| `user-disabled` | "This account has been disabled" | Admin disabled account |
| `user-not-found` | "No account found with this email" | Email doesn't exist |
| `wrong-password` | "Incorrect password" | Wrong password |
| `invalid-credential` | "Invalid email or password" | Firebase's combined error |
| `email-already-in-use` | "An account already exists with this email" | Signup with existing email |
| `weak-password` | "Password must be at least 6 characters" | Firebase minimum |
| `too-many-requests` | "Too many attempts. Please try again later" | Rate limited |
| `network-request-failed` | "Network error. Check your connection" | No internet |
| `operation-not-allowed` | "This sign in method is not enabled" | Method disabled in Firebase |
| `account-exists-with-different-credential` | "An account already exists with this email using a different sign-in method" | Google vs Email conflict |
| `requires-recent-login` | "Please sign in again to perform this action" | Sensitive operation |
| `credential-already-in-use` | "This credential is already linked to another account" | Link conflict |

### Google Sign-In Errors

| Error | User Message |
|-------|--------------|
| User cancels | "Google sign in was cancelled" |
| Generic failure | "Google sign in failed. Please try again" |

---

## 🇬🇭 Ghana-Specific UX Considerations

### Network Reality
- **Assumption:** Users may have unstable or slow internet
- **Solution:** Offline-first architecture, clear network error messages
- **UX:** Show "Network error. Check your connection" - don't assume WiFi

### Email Culture
- **Reality:** Some users rarely check email, prefer WhatsApp/SMS
- **Solution:** Email verification is simple (just click link), auto-detection in app
- **UX:** Clear instructions, no code typing required

### Device Diversity
- **Reality:** Mix of low-end and flagship phones
- **Solution:** Lightweight animations, no heavy graphics
- **UX:** Touch targets 48px+, clear visual feedback

### Trust Factors
- **Reality:** Users cautious about new apps asking for data
- **Solution:** Guest mode available, explain why verification matters
- **UX:** "Verify your email to secure your account and ratings"

### Language
- **Current:** English (Ghana's official language)
- **Future:** Consider Twi, Ga, Ewe for broader reach
- **UX:** Simple, clear sentences, avoid technical jargon

---

## 🎯 UX Patterns Used

### 1. Progressive Disclosure
- Guest mode → Later upgrade to full account
- Don't force signup until necessary

### 2. Error Prevention
- Disable submit button while loading
- Real-time validation on form fields
- Password visibility toggle

### 3. Clear Feedback
- Loading spinners on buttons
- Success states with clear next steps
- Error snackbars dismissible via swipe or "OK"

### 4. Helpful Recovery
- "User not found" → Offer to create account
- "Forgot password?" easily accessible
- Resend verification email option

### 5. Security Without Friction
- Click-to-verify (not code entry)
- Google Sign-In pre-verified
- 60-second cooldown on resends (prevent spam)

---

## 🔐 Security Measures

| Feature | Implementation |
|---------|---------------|
| Password minimum | 6 characters (Firebase default) |
| Email verification | Required for email signups |
| Rate limiting | Firebase's `too-many-requests` |
| Secure credential storage | Handled by Firebase SDK |
| Session management | Firebase persistent auth |
| Password reset | Via email link (not in-app) |

---

## 📊 State Management

Auth state is managed via Riverpod:

```dart
// States
AuthInitial      → App just started
AuthLoading      → Operation in progress
AuthAuthenticated → User signed in
AuthUnauthenticated → User signed out
AuthErrorState   → Operation failed (contains message)

// Providers
authStateProvider       → Stream of auth changes
currentUserProvider     → Current user (nullable)
isSignedInProvider      → Boolean check
isGuestProvider         → Is anonymous user
authNotifierProvider    → Actions (signIn, signUp, etc.)
```

---

## 🧪 Test Scenarios

### Happy Paths
- [ ] Sign up with valid email → Verification screen
- [ ] Verify email → Home
- [ ] Sign in with verified account → Home
- [ ] Google sign in → Home
- [ ] Guest mode → Home
- [ ] Password reset → Email sent
- [ ] Sign out → Auth screen

### Error Paths
- [ ] Sign in with unregistered email → Offer signup
- [ ] Sign in with wrong password → Error message
- [ ] Sign in without verification → Verification screen
- [ ] Sign up with existing email → Error message
- [ ] Too many attempts → Rate limit message
- [ ] Network offline → Network error message
- [ ] Cancel Google sign in → Cancelled message

### Edge Cases
- [ ] App killed during verification → Resume polling on return
- [ ] Deep link from verification email → Should verify and redirect
- [ ] Guest trying to rate → Prompt to upgrade account
- [ ] Already verified user going to verification screen → Should redirect to home

---

## 📝 Future Enhancements

1. **Biometric Login** - For returning users
2. **Phone Number Auth** - Popular in Ghana
3. **Social Recovery** - If locked out
4. **Remember Me** - Persistent sessions
5. **Multi-language** - Twi, Ga, Ewe support

---

## 🧭 Navigation UX

### Bottom Navigation Bar
- **Floating design** - Semi-transparent, floats over content
- **4 tabs max** - Home, Stats, Search, Settings
- **Active state** - Icon fills, slight scale animation
- **Haptic feedback** - Light vibration on tap

### Navigation Guards
The router automatically handles:
```
Unauthenticated user → Public routes only (splash, onboarding, auth)
Unverified email user → Email verification screen
Authenticated user → All routes
Guest user → All routes (prompted to upgrade for certain actions)
```

### Edge Cases
| Scenario | Handling |
|----------|----------|
| Deep link to protected route | Redirect to auth, then back after login |
| Back button on home | Show exit confirmation |
| Tab switch while loading | Cancel previous request |

---

## 🚗 Speed Tracking UX (Week 3+)

### Display Requirements
- **Large speedometer** - Readable while driving (glanceable)
- **Color coding** - Green (safe), Yellow (warning), Red (danger)
- **Audio alerts** - Optional voice warnings for speed
- **Minimal interaction** - Start/stop only, no typing while driving

### Edge Cases to Handle
| Scenario | UX |
|----------|-----|
| GPS not available | Show "Acquiring GPS..." with retry |
| GPS inaccurate (tunnels) | Show last known speed with "?" indicator |
| App backgrounded | Continue tracking with notification |
| Low battery | Warn user, suggest reducing GPS frequency |
| No location permission | Clear explanation of why needed |

### Ghana-Specific Speed Considerations
- Default speed limit: 50 km/h (urban), 100 km/h (highway)
- "Sleeping policemen" (speed bumps) - Consider adding alerts
- Common speeding areas - Could pre-warn based on location

---

## ⭐ Driver Rating UX (Week 5+)

### Rating Flow
```
1. Enter plate number (manual or camera)
2. Confirm vehicle details (if found)
3. Select rating (1-5 stars)
4. Add optional comment
5. Submit & see confirmation
```

### Plate Number Input
- **Format hint:** "GR-1234-20" shown as placeholder
- **Auto-format:** Add hyphens automatically
- **Validation:** Real-time, Ghana format check
- **Camera option:** OCR for quick entry

### Edge Cases
| Scenario | UX |
|----------|-----|
| Plate not found in system | Allow rating new vehicle |
| Duplicate rating (same day) | Show previous rating, allow update |
| Offensive comment | Filter before submit, warn user |
| Guest trying to rate | Prompt to create account |
| Offline rating | Save locally, sync when online |

### Ghana-Specific Rating Considerations
- Plate format variations (old vs new format)
- Commercial vs private vehicles (different expectations)
- Taxi/Trotro behavior patterns
- Language for comments (allow Twi/English mix?)

---

## 🔍 Search UX (Week 6+)

### Search Flow
```
1. Enter plate number or partial
2. See matching results with ratings
3. Tap to view full vehicle history
4. See breakdown by rating category
```

### Search Patterns
- **Exact match** - Full plate number
- **Partial match** - First letters/numbers
- **Recent searches** - Quick access to previous
- **Nearby vehicles** - Location-based (future)

### Edge Cases
| Scenario | UX |
|----------|-----|
| No results | "No ratings yet for this vehicle" |
| Many results | Paginate, show most relevant first |
| Offline search | Search local cache only |
| Slow network | Show skeleton loading |

---

## ⚠️ Error Handling Patterns

### Error Message Guidelines

| Type | Style | Duration | Action |
|------|-------|----------|--------|
| **Validation** | Inline below field | Until fixed | None needed |
| **Network** | Snackbar | 4 seconds | "Retry" button |
| **Permission** | Full dialog | Until dismissed | "Settings" button |
| **Fatal** | Full screen | Until resolved | "Try Again" |

### Error Message Writing
```
✅ GOOD:
- "Check your internet connection"
- "This email is already registered. Sign in instead?"
- "Please allow location access to track your speed"

❌ BAD:
- "Error 403: Forbidden"
- "null is not a function"
- "Something went wrong"
```

### Retry Logic
```dart
// Exponential backoff for network errors
Attempt 1: immediate
Attempt 2: 1 second wait
Attempt 3: 2 seconds wait
Attempt 4: 4 seconds wait
Attempt 5: Give up, show error
```

---

## 📴 Offline-First UX

### Sync Status Indicators
- **Green dot** - Fully synced
- **Yellow dot** - Syncing in progress
- **Red dot** - Sync failed (tap to retry)

### Offline Capabilities
| Feature | Offline Support |
|---------|-----------------|
| View past trips | ✅ Full |
| Track current speed | ✅ Full (GPS only) |
| Rate a driver | ✅ Queued for sync |
| Search vehicles | ⚠️ Local cache only |
| View own ratings | ✅ Full |
| See vehicle history | ⚠️ Cached data only |

### Conflict Resolution
When same data modified offline and online:
1. **Last write wins** for simple fields
2. **Merge** for lists (e.g., trip points)
3. **User prompt** for conflicting ratings

---

## ♿ Accessibility

### Requirements
- [ ] Min touch target: 48x48 dp
- [ ] Color contrast: 4.5:1 minimum
- [ ] All images have alt text
- [ ] Works with screen readers
- [ ] Supports system font scaling
- [ ] No information conveyed by color alone

### Testing
- Enable TalkBack (Android) / VoiceOver (iOS)
- Set font to largest size
- Enable high contrast mode
- Test with one hand only

---

## ✅ Testing Checklist (All Features)

### Before Implementing Any Feature

- [ ] Read this UX document
- [ ] Review Ghana-specific considerations
- [ ] Identify all edge cases
- [ ] Plan error handling
- [ ] Consider offline behavior

### After Implementing Any Feature

- [ ] Test happy path
- [ ] Test all error paths
- [ ] Test offline behavior
- [ ] Test with slow network (dev tools)
- [ ] Test with large font size
- [ ] Test on low-end device
- [ ] Test in both light and dark mode
- [ ] Update this document with new learnings

---

## 📚 Adding New Features - UX Process

1. **Research Phase**
   - What problem does this solve?
   - How do similar apps handle it?
   - What are Ghana-specific considerations?

2. **Design Phase**
   - Map out the happy path
   - List all edge cases
   - Define error states
   - Plan offline behavior

3. **Implementation Phase**
   - Follow design system
   - Implement error handling first
   - Add loading states
   - Test on slow network

4. **Documentation Phase**
   - Update this document
   - Add to test scenarios
   - Document any new patterns

---

**Last Updated:** Week 2 (Complete UX Guide)
**Status:** Living Document - Update with each feature
