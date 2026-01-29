# RoadGuard Design System

> **"The Digital Copilot"** - A Neo-Modern Bento UI with floating elements, high contrast, and fluid motion.

---

## 🎨 Design Philosophy

This design language creates an interface that feels like a **premium physical object**. The app should feel like manipulating physical objects on a fluid surface, not flipping through pages.

### Core Principles
1. **Tactile & Physical** - Elements feel like real buttons that can be pressed
2. **Layered & Floating** - Clear depth separation between UI layers
3. **Fluid & Elastic** - Motion that stretches, bounces, and flows
4. **Glanceable** - Complex data digestible at a glance

---

## 🌙 Color System

### Dark Mode (Primary - "The Cockpit")
```dart
// Backgrounds
background:         Color(0xFF000000)  // True OLED black
surface:            Color(0xFF0F172A)  // Deep midnight blue
surfaceVariant:     Color(0xFF1E293B)  // Elevated cards
surfaceElevated:    Color(0xFF334155)  // Highest elevation

// Primary - Neon Volt (Actions, Success)
primary:            Color(0xFFCDFF00)  // Electric yellow-green
primaryContainer:   Color(0xFF1A2E05)  // Dark green container
onPrimary:          Color(0xFF000000)  // Black text on primary

// Secondary - Cyber Blue (Data, Maps)
secondary:          Color(0xFF38BDF8)  // Cool cyan blue
secondaryContainer: Color(0xFF0C4A6E)  // Dark blue container
onSecondary:        Color(0xFF000000)  // Black text on secondary

// Error - Infrared (Alerts, Bad Rating)
error:              Color(0xFFFF3B30)  // Bright red
errorContainer:     Color(0xFF3D0A07)  // Dark red container
onError:            Color(0xFFFFFFFF)  // White text on error

// Warning - Alert Orange
warning:            Color(0xFFFF9500)  // Bright orange
warningContainer:   Color(0xFF3D2400)  // Dark orange container

// Text
textPrimary:        Color(0xFFFFFFFF)  // Pure white
textSecondary:      Color(0xFF94A3B8)  // Muted gray
textTertiary:       Color(0xFF64748B)  // Hint text
textDisabled:       Color(0xFF475569)  // Disabled state

// Borders & Dividers
outline:            Color(0xFF334155)  // Subtle borders
outlineVariant:     Color(0xFF475569)  // Stronger borders
```

### Light Mode (Secondary - "The Soft Look")
```dart
// Backgrounds
background:         Color(0xFFF8FAFC)  // Off-white
surface:            Color(0xFFFFFFFF)  // Pure white cards
surfaceVariant:     Color(0xFFF1F5F9)  // Input backgrounds
surfaceElevated:    Color(0xFFFFFFFF)  // Elevated (with shadow)

// Primary - Deep Volt
primary:            Color(0xFF84CC16)  // Lime green
primaryContainer:   Color(0xFFECFCCB)  // Light green container
onPrimary:          Color(0xFFFFFFFF)  // White text on primary

// Secondary - Ocean Blue
secondary:          Color(0xFF0EA5E9)  // Sky blue
secondaryContainer: Color(0xFFE0F2FE)  // Light blue container
onSecondary:        Color(0xFFFFFFFF)  // White text on secondary

// Error
error:              Color(0xFFEF4444)  // Red
errorContainer:     Color(0xFFFEE2E2)  // Light red container

// Warning
warning:            Color(0xFFF59E0B)  // Amber
warningContainer:   Color(0xFFFEF3C7)  // Light amber container

// Text
textPrimary:        Color(0xFF0F172A)  // Almost black
textSecondary:      Color(0xFF64748B)  // Muted gray
textTertiary:       Color(0xFF94A3B8)  // Hint text

// Borders
outline:            Color(0xFFE2E8F0)  // Light borders
outlineVariant:     Color(0xFFCBD5E1)  // Stronger borders
```

### Semantic Colors (Both Modes)
```dart
// Rating Colors
goodDriver:         Color(0xFF10B981)  // Emerald green
badDriver:          Color(0xFFEF4444)  // Red

// Status Colors
online:             Color(0xFF22C55E)  // Green
offline:            Color(0xFF6B7280)  // Gray
tracking:           Color(0xFF3B82F6)  // Blue pulse
```

---

## 📐 Spacing & Dimensions

### Spacing Scale (8px base)
```dart
spacing4:    4.0   // Tight - icon gaps
spacing8:    8.0   // Small - text gaps
spacing12:   12.0  // Medium-small
spacing16:   16.0  // Default - card padding
spacing20:   20.0  // Medium
spacing24:   24.0  // Section gaps
spacing32:   32.0  // Large sections
spacing48:   48.0  // Page padding
spacing64:   64.0  // Hero spacing
```

### Border Radius
```dart
radiusNone:    0.0   // Sharp corners
radiusSmall:   8.0   // Buttons, chips
radiusMedium:  12.0  // Cards, inputs (DEFAULT)
radiusLarge:   16.0  // Large cards
radiusXLarge:  24.0  // Bottom sheets, dialogs
radiusXXLarge: 32.0  // Floating nav bar
radiusFull:    999.0 // Pills, circular buttons
```

### Touch Targets
```dart
minTouchTarget:  48.0  // Minimum tappable area
buttonHeight:    56.0  // Primary buttons
inputHeight:     56.0  // Text fields
iconButtonSize:  48.0  // Icon buttons
fabSize:         64.0  // Floating action button
```

### Screen Padding
```dart
screenPaddingHorizontal: 20.0
screenPaddingVertical:   24.0
cardPadding:             16.0
listItemPadding:         12.0
```

---

## 🔤 Typography

### Font Families
```dart
// Primary: System default (SF Pro on iOS, Roboto on Android)
fontFamilyPrimary: null  // Uses system default

// Numbers: Monospace for speed display
fontFamilyMono: 'SF Mono', 'Roboto Mono'
```

### Text Styles
```dart
// Display - Speed numbers
displayLarge:   72px / Bold / Mono    // "85" speed
displayMedium:  48px / Bold / Mono    // Stats numbers
displaySmall:   32px / Bold           // Large headers

// Headlines - Screen titles
headlineLarge:  28px / SemiBold       // "Hello, User"
headlineMedium: 24px / SemiBold       // Section titles
headlineSmall:  20px / SemiBold       // Card titles

// Titles - UI elements
titleLarge:     18px / SemiBold       // Button text
titleMedium:    16px / Medium         // Tab labels
titleSmall:     14px / Medium         // Chip labels

// Body - Content
bodyLarge:      16px / Regular        // Primary body
bodyMedium:     14px / Regular        // Secondary body
bodySmall:      12px / Regular        // Captions

// Labels
labelLarge:     14px / Medium         // Form labels
labelMedium:    12px / Medium         // Small labels
labelSmall:     11px / Medium         // Badges, tags
```

---

## 🧩 Component Library

### 1. The Floating Bottom Navigation ("Floating Island")

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│    ┌───────────────────────────────────────────────────────┐   │
│    │                                                       │   │
│    │   ┌─────────────┐                                    │   │
│    │   │ 🏠  Home    │     📊       🔍       ⚙️           │   │
│    │   └─────────────┘   Stats   Search  Settings        │   │
│    │                                                       │   │
│    └───────────────────────────────────────────────────────┘   │
│                     ↑                                           │
│              20-30px from bottom                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Specifications:**
- Shape: Stadium/pill shape (radiusXXLarge: 32px)
- Position: Floating 24px from bottom edge
- Margin: 20px from left/right edges
- Height: 64px
- Background: 
  - Dark mode: `surface` with subtle border
  - Light mode: `surfaceElevated` with soft shadow

**Active State ("Mercury Indicator"):**
- Background pill: `primaryContainer` with primary border
- Icon + Label: `primary` color
- Radius of pill: `radiusFull`
- Animation: Slides/morphs to new position (300ms ease-out)

**Inactive State:**
- Icon only (no label)
- Color: `textSecondary`
- Scale: 0.95x of active

**Motion:**
- Tab switch: "Mercury slide" - indicator stretches slightly as it moves
- Screen transition: Content slides behind (parallax)

---

### 2. Cards ("Bento Tiles")

**Standard Card:**
```dart
Container(
  decoration: BoxDecoration(
    color: theme.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: theme.outline, width: 1),
  ),
  padding: EdgeInsets.all(spacing16),
)
```

**Elevated Card (Dark Mode):**
```dart
Container(
  decoration: BoxDecoration(
    color: theme.surfaceVariant,
    borderRadius: BorderRadius.circular(radiusMedium),
    // No shadow in dark mode - use color elevation
  ),
)
```

**Elevated Card (Light Mode):**
```dart
Container(
  decoration: BoxDecoration(
    color: theme.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
)
```

**Press State ("Squish Effect"):**
- Scale down to 0.97 on press
- Spring back on release
- Duration: 100ms press, 200ms release

---

### 3. Buttons

**Primary Button (Neon Volt):**
```
┌─────────────────────────────────────┐
│          Start Tracking             │
└─────────────────────────────────────┘
```
- Background: `primary`
- Text: `onPrimary` (black)
- Height: 56px
- Radius: `radiusMedium` (12px) or `radiusFull` for pill
- Full width or content-hugging

**Secondary Button (Outlined):**
- Background: transparent
- Border: 1px `outline`
- Text: `textPrimary`

**Danger Button:**
- Background: `error`
- Text: `onError` (white)

**Icon Button:**
- Size: 48x48
- Radius: `radiusMedium` or `radiusFull`
- Background: `surfaceVariant`

---

### 4. The Speedometer ("Liquid Ring")

```
            ╭─────────────────────╮
           ╱                       ╲
          │      ┌─────────┐       │
          │      │         │       │
          │      │   85    │       │
          │      │  km/h   │       │
          │      └─────────┘       │
           ╲                       ╱
            ╰─────────────────────╯
```

**Specifications:**
- Outer ring: Circular progress indicator
- Ring color: Gradient from `secondary` to `primary`
- Ring width: 8px
- Center number: `displayLarge` mono font
- Unit label: `bodyMedium` below number
- Alert state (80km/h): Ring turns `error`, pulses

**Animation:**
- Ring fills smoothly as speed increases
- Number counts up/down with slight bounce
- Alert: Ring pulses (1s cycle), border glows red

---

### 5. Input Fields

**Search Bar (Floating):**
```
┌──────────────────────────────────────────┐
│  🔍  Enter number plate...               │
└──────────────────────────────────────────┘
```
- Height: 56px
- Radius: `radiusMedium` or `radiusFull` for pill style
- Background: `surfaceVariant`
- Border: none (or 1px `outline` on focus)
- Icon: `textTertiary`
- Placeholder: `textTertiary`

**Text Field (Form):**
- Same as search but with label above
- Focus state: Border becomes `primary`

---

### 6. Rating Cards

**Good/Bad Selection:**
```
┌────────────────────┐  ┌────────────────────┐
│                    │  │                    │
│        😊          │  │        😞          │
│                    │  │                    │
│      GOOD          │  │       BAD          │
│                    │  │                    │
└────────────────────┘  └────────────────────┘
```

- Size: Equal width, square-ish aspect
- Radius: `radiusLarge` (16px)
- Default: `surfaceVariant` background
- Selected Good: `goodDriver` background
- Selected Bad: `badDriver` background
- Animation: Selected expands slightly, other grays out

---

### 7. Chips (Quick Feedback)

```
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ Safe driver  │ │ Overspeeding │ │ Clean car    │
└──────────────┘ └──────────────┘ └──────────────┘
```

- Height: 36px
- Radius: `radiusFull`
- Padding: 12px horizontal
- Unselected: `surfaceVariant` bg, `textSecondary` text
- Selected: `primaryContainer` bg, `primary` text/border

---

## 🎬 Motion & Animation

### Timing Functions
```dart
// Standard curve for most animations
standardCurve: Curves.easeOutCubic

// Bouncy curve for playful interactions
bouncyCurve: Curves.elasticOut

// Sharp curve for quick feedback
sharpCurve: Curves.easeOut
```

### Duration Scale
```dart
instant:     50ms   // Micro-feedback (color changes)
fast:        150ms  // Button presses, toggles
normal:      250ms  // Card transitions, slides
slow:        400ms  // Page transitions
verySlow:    600ms  // Hero animations, morphs
```

### Animation Patterns

**1. Mercury Slide (Nav Indicator):**
- Duration: 300ms
- Curve: easeOutCubic
- The indicator stretches 10% wider during movement

**2. Card Squish (Press):**
- Press: Scale to 0.97 in 100ms
- Release: Spring back with slight overshoot (1.02 → 1.0)

**3. Hero Morph (Card → Detail):**
- Duration: 400ms
- Card background expands to fill screen
- Image scales up continuously (shared element)

**4. Staggered Entrance:**
- Each card delays 50ms after previous
- Slide up from 20px below + fade in
- Duration: 300ms per item

**5. Liquid Ring (Speedometer):**
- Smooth fill following speed changes
- Duration: 200ms per update
- Alert pulse: 1000ms cycle, ease-in-out

**6. Rubber-Banding (Scroll):**
- Overscroll stretches content
- Springs back on release
- Built into Flutter's scroll physics

**7. Haptic Feedback:**
- Light tap: On button press
- Medium tap: On selection confirm
- Heavy tap: On alert (80km/h warning)

---

## 📱 Screen Layouts

### Dashboard (Home)
```
┌─────────────────────────────────────────┐
│ Status Bar                              │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🔍 Search number plate...           │ │ ← Floating search
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 💡 Safety tip: 70% of accidents...  │ │ ← Info ticker
│ └─────────────────────────────────────┘ │
│                                         │
│            ╭───────────────╮            │
│           ╱                 ╲           │
│          │                   │          │
│          │        0          │          │ ← Speedometer
│          │      km/h         │          │
│           ╲                 ╱           │
│            ╰───────────────╯            │
│                                         │
│        📍 Waiting for location          │
│                                         │
│     ┌───────────────────────────┐       │
│     │ ▶  HOLD TO START TRACKING │       │ ← Primary action
│     └───────────────────────────┘       │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │ 🏠 Home │  📊  │  🔍  │  ⚙️   │   │ ← Floating nav
│   └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Active Tracking
```
┌─────────────────────────────────────────┐
│ Status Bar                        🔴REC │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │                                 │   │
│   │           [MAP VIEW]            │   │ ← Route map
│   │                                 │   │
│   └─────────────────────────────────┘   │
│                                         │
│            ╭───────────────╮            │
│           ╱    ╱╲    ╲     ╲           │
│          │    ╱  ╲    │     │          │
│          │   85       │     │          │ ← Large speed
│          │   km/h     │     │          │
│           ╲          ╱     ╱           │
│            ╰───────────────╯            │
│                                         │
│   ┌────────┐ ┌────────┐ ┌────────┐     │
│   │   95   │ │   68   │ │  4.2   │     │ ← Stats row
│   │  TOP   │ │  AVG   │ │   KM   │     │
│   └────────┘ └────────┘ └────────┘     │
│                                         │
│     ┌───────────────────────────┐       │
│     │     ⏹  STOP TRIP          │       │ ← Stop (red)
│     └───────────────────────────┘       │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### Trip Summary
```
┌─────────────────────────────────────────┐
│  ←                Trip Summary          │
├─────────────────────────────────────────┤
│                                         │
│   ┌─────────────────────────────────┐   │
│   │                                 │   │
│   │    [MAP WITH ROUTE PATH]        │   │
│   │     ●━━━━━━━━━━━━━━━━●          │   │
│   │   Start              End        │   │
│   │                                 │   │
│   └─────────────────────────────────┘   │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │      95        │ │      68        │ │
│   │   TOP SPEED    │ │   AVG SPEED    │ │
│   │     km/h       │ │     km/h       │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│   ┌────────────────┐ ┌────────────────┐ │
│   │     4.2        │ │     12:34      │ │
│   │   DISTANCE     │ │   DURATION     │ │
│   │      km        │ │                │ │
│   └────────────────┘ └────────────────┘ │
│                                         │
│     ┌───────────────────────────┐       │
│     │    📷 RATE THIS DRIVER    │       │
│     └───────────────────────────┘       │
│                                         │
│           Skip for now                  │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🌓 Theme Implementation

All styles MUST come from the theme system:

```dart
// Access colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface

// Access text styles
Theme.of(context).textTheme.displayLarge
Theme.of(context).textTheme.bodyMedium

// Custom extensions
context.appDimensions.spacing16
context.appDimensions.radiusMedium
```

---

## ✅ Design Checklist

Before implementing ANY screen:

- [ ] Background uses correct theme color
- [ ] Cards use proper elevation/borders for mode
- [ ] Text uses theme text styles
- [ ] Colors adapt to light/dark mode
- [ ] Touch targets are minimum 48px
- [ ] Spacing follows 8px grid
- [ ] Border radius is consistent
- [ ] Animations follow timing guidelines
- [ ] Bottom nav is floating style
- [ ] Search bar is floating pill style

---

**Remember:** This app should feel like a **premium digital cockpit** - smooth, tactile, and professional.
