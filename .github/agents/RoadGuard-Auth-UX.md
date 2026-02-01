# RoadGuard Authentication UX Guide

> Comprehensive guide to all authentication flows, error handling, and Ghana-specific UX considerations.

---

## 📱 Authentication Methods

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

**Last Updated:** Week 2 (Auth Implementation)
**Status:** Production Ready
