# RoadGuard Cloud Functions

> **PURPOSE:** Firebase Cloud Functions for server-side operations. Deploy these to Firebase Functions.

---

## 📦 Setup

### Directory Structure

```
functions/
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts              # Main exports
│   ├── ratings/
│   │   ├── onRatingCreated.ts
│   │   └── aggregateRatings.ts
│   ├── leaderboards/
│   │   └── calculateLeaderboards.ts
│   ├── maintenance/
│   │   └── cleanupOldData.ts
│   └── notifications/
│       └── sendAlerts.ts
└── lib/                       # Compiled output
```

### package.json

```json
{
  "name": "roadguard-functions",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions"
  },
  "engines": {
    "node": "18"
  },
  "main": "lib/index.js",
  "dependencies": {
    "firebase-admin": "^11.11.0",
    "firebase-functions": "^4.5.0"
  },
  "devDependencies": {
    "typescript": "^5.2.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

---

## 🎯 Function: Rating Aggregation

When a new rating is created, update the driver's aggregate stats.

```typescript
// src/ratings/onRatingCreated.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

interface Rating {
  raterId: string;
  isGood: boolean;
  tags: string[];
  comment?: string;
  createdAt: admin.firestore.Timestamp;
  idempotencyKey?: string;
}

interface DriverStats {
  plateNumber: string;
  totalRatings: number;
  goodRatings: number;
  badRatings: number;
  averageRating: number;
  commonTags: string[];
  tagCounts: Record<string, number>;
  lastUpdated: admin.firestore.Timestamp;
}

export const onRatingCreated = functions.firestore
  .document('drivers/{plateNumber}/ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data() as Rating;
    const plateNumber = context.params.plateNumber;
    
    console.log(`New rating for ${plateNumber}: ${rating.isGood ? 'Good' : 'Bad'}`);
    
    // ===== IDEMPOTENCY CHECK =====
    if (rating.idempotencyKey) {
      const idempotencyRef = db.collection('idempotency_keys').doc(rating.idempotencyKey);
      const existing = await idempotencyRef.get();
      
      if (existing.exists) {
        console.log(`Duplicate rating detected: ${rating.idempotencyKey}`);
        // Delete the duplicate
        await snap.ref.delete();
        return;
      }
      
      // Mark as processed
      await idempotencyRef.set({
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        operation: 'rating_create',
        plateNumber: plateNumber,
      });
    }
    
    // ===== UPDATE DRIVER STATS =====
    const driverRef = db.collection('drivers').doc(plateNumber);
    
    await db.runTransaction(async (transaction) => {
      const driverDoc = await transaction.get(driverRef);
      
      let stats: DriverStats;
      
      if (driverDoc.exists) {
        stats = driverDoc.data() as DriverStats;
      } else {
        // New driver
        stats = {
          plateNumber: plateNumber,
          totalRatings: 0,
          goodRatings: 0,
          badRatings: 0,
          averageRating: 0,
          commonTags: [],
          tagCounts: {},
          lastUpdated: admin.firestore.Timestamp.now(),
        };
      }
      
      // Update counts
      stats.totalRatings += 1;
      if (rating.isGood) {
        stats.goodRatings += 1;
      } else {
        stats.badRatings += 1;
      }
      
      // Recalculate average (Good = 5 stars, Bad = 1 star)
      const totalScore = (stats.goodRatings * 5) + (stats.badRatings * 1);
      stats.averageRating = Math.round((totalScore / stats.totalRatings) * 10) / 10;
      
      // Update tag counts
      for (const tag of rating.tags || []) {
        stats.tagCounts[tag] = (stats.tagCounts[tag] || 0) + 1;
      }
      
      // Get top 5 tags
      stats.commonTags = Object.entries(stats.tagCounts)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5)
        .map(([tag]) => tag);
      
      stats.lastUpdated = admin.firestore.Timestamp.now();
      
      transaction.set(driverRef, stats, { merge: true });
    });
    
    console.log(`Updated stats for ${plateNumber}`);
  });
```

---

## 🏆 Function: Leaderboard Calculation

Calculate weekly and monthly leaderboards per region.

```typescript
// src/leaderboards/calculateLeaderboards.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface LeaderboardEntry {
  rank: number;
  userId: string;
  displayName: string;
  score: number;
  tripCount: number;
  avgSpeed: number;
  updatedAt: admin.firestore.Timestamp;
}

// Run every day at midnight
export const calculateDailyLeaderboards = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Africa/Accra')
  .onRun(async (context) => {
    console.log('Starting daily leaderboard calculation');
    
    const regions = ['GR', 'AS', 'CR', 'ER', 'NR', 'WR', 'VR', 'UE', 'UW'];
    
    for (const region of regions) {
      await calculateRegionLeaderboard(region, 'weekly');
      await calculateRegionLeaderboard(region, 'monthly');
    }
    
    console.log('Leaderboard calculation complete');
  });

async function calculateRegionLeaderboard(
  region: string, 
  period: 'weekly' | 'monthly'
) {
  // Determine date range
  const now = new Date();
  let startDate: Date;
  
  if (period === 'weekly') {
    startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  } else {
    startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  }
  
  // Query trips in this region and time period
  const tripsSnapshot = await db.collection('trips')
    .where('region', '==', region)
    .where('startTime', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .get();
  
  // Aggregate by user
  const userStats: Record<string, {
    tripCount: number;
    totalDistance: number;
    totalDuration: number;
    avgSpeeds: number[];
  }> = {};
  
  for (const tripDoc of tripsSnapshot.docs) {
    const trip = tripDoc.data();
    const userId = trip.userId;
    
    if (!userStats[userId]) {
      userStats[userId] = {
        tripCount: 0,
        totalDistance: 0,
        totalDuration: 0,
        avgSpeeds: [],
      };
    }
    
    userStats[userId].tripCount += 1;
    userStats[userId].totalDistance += trip.distance || 0;
    userStats[userId].totalDuration += trip.duration || 0;
    userStats[userId].avgSpeeds.push(trip.avgSpeed || 0);
  }
  
  // Calculate scores and rank
  const entries: Array<{userId: string; score: number; stats: typeof userStats['']}> = [];
  
  for (const [userId, stats] of Object.entries(userStats)) {
    // Score formula: trips * 10 + km + safety bonus
    const avgSpeed = stats.avgSpeeds.reduce((a, b) => a + b, 0) / stats.avgSpeeds.length;
    const safetyBonus = avgSpeed < 80 ? 50 : 0; // Bonus for safe driving
    
    const score = (stats.tripCount * 10) + stats.totalDistance + safetyBonus;
    
    entries.push({ userId, score, stats });
  }
  
  // Sort by score descending
  entries.sort((a, b) => b.score - a.score);
  
  // Get user display names and write top 100
  const leaderboardRef = db.collection('leaderboards')
    .doc(region)
    .collection(period);
  
  // Clear old entries
  const oldEntries = await leaderboardRef.get();
  const batch = db.batch();
  for (const doc of oldEntries.docs) {
    batch.delete(doc.ref);
  }
  
  // Write new entries
  for (let i = 0; i < Math.min(entries.length, 100); i++) {
    const entry = entries[i];
    
    // Get user display name
    const userDoc = await db.collection('users').doc(entry.userId).get();
    const displayName = userDoc.exists 
      ? userDoc.data()?.displayName || 'Anonymous'
      : 'Anonymous';
    
    const leaderboardEntry: LeaderboardEntry = {
      rank: i + 1,
      userId: entry.userId,
      displayName: displayName,
      score: Math.round(entry.score),
      tripCount: entry.stats.tripCount,
      avgSpeed: Math.round(
        entry.stats.avgSpeeds.reduce((a, b) => a + b, 0) / 
        entry.stats.avgSpeeds.length
      ),
      updatedAt: admin.firestore.Timestamp.now(),
    };
    
    batch.set(leaderboardRef.doc(String(i + 1)), leaderboardEntry);
  }
  
  await batch.commit();
  console.log(`Updated ${period} leaderboard for ${region}: ${entries.length} users`);
}
```

---

## 🧹 Function: Data Cleanup

Clean up old/stale data to manage storage costs.

```typescript
// src/maintenance/cleanupOldData.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Run every Sunday at 3 AM
export const cleanupOldData = functions.pubsub
  .schedule('0 3 * * 0')
  .timeZone('Africa/Accra')
  .onRun(async (context) => {
    console.log('Starting weekly cleanup');
    
    await cleanupIdempotencyKeys();
    await cleanupOldNotifications();
    await cleanupAnonymousUsers();
    
    console.log('Weekly cleanup complete');
  });

// Remove idempotency keys older than 7 days
async function cleanupIdempotencyKeys() {
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  
  const snapshot = await db.collection('idempotency_keys')
    .where('processedAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
    .limit(500) // Process in batches
    .get();
  
  if (snapshot.empty) {
    console.log('No old idempotency keys to clean');
    return;
  }
  
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  
  await batch.commit();
  console.log(`Deleted ${snapshot.size} old idempotency keys`);
}

// Remove old notification records
async function cleanupOldNotifications() {
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
  
  const snapshot = await db.collectionGroup('notifications')
    .where('sentAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
    .limit(500)
    .get();
  
  if (snapshot.empty) return;
  
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  
  await batch.commit();
  console.log(`Deleted ${snapshot.size} old notifications`);
}

// Remove anonymous users who haven't been active in 90 days
async function cleanupAnonymousUsers() {
  const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  
  const snapshot = await db.collection('users')
    .where('isGuest', '==', true)
    .where('lastLoginAt', '<', admin.firestore.Timestamp.fromDate(cutoff))
    .limit(100)
    .get();
  
  if (snapshot.empty) {
    console.log('No inactive anonymous users to clean');
    return;
  }
  
  for (const doc of snapshot.docs) {
    const userId = doc.id;
    
    // Delete user's trips
    const tripsSnapshot = await db.collection('trips')
      .where('userId', '==', userId)
      .get();
    
    const batch = db.batch();
    for (const tripDoc of tripsSnapshot.docs) {
      batch.delete(tripDoc.ref);
    }
    
    // Delete user document
    batch.delete(doc.ref);
    
    // Delete Firebase Auth user
    try {
      await admin.auth().deleteUser(userId);
    } catch (e) {
      console.log(`Could not delete auth user ${userId}: ${e}`);
    }
    
    await batch.commit();
  }
  
  console.log(`Cleaned up ${snapshot.size} inactive anonymous users`);
}
```

---

## 🔔 Function: Push Notifications (Future)

Send push notifications for various events.

```typescript
// src/notifications/sendAlerts.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

// When someone rates a driver, notify them (if they have the app)
export const onDriverRated = functions.firestore
  .document('drivers/{plateNumber}/ratings/{ratingId}')
  .onCreate(async (snap, context) => {
    const rating = snap.data();
    const plateNumber = context.params.plateNumber;
    
    // Check if this plate is registered to a user
    const userQuery = await db.collection('users')
      .where('registeredPlates', 'array-contains', plateNumber)
      .limit(1)
      .get();
    
    if (userQuery.empty) return; // Plate not registered
    
    const userDoc = userQuery.docs[0];
    const fcmToken = userDoc.data().fcmToken;
    
    if (!fcmToken) return; // User hasn't enabled notifications
    
    const notification: NotificationPayload = {
      title: 'New Rating Received',
      body: rating.isGood 
        ? '👍 Someone gave you a positive rating!'
        : '👎 Someone gave you feedback.',
      data: {
        type: 'rating_received',
        plateNumber: plateNumber,
        ratingId: context.params.ratingId,
      },
    };
    
    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: notification.data,
        android: {
          priority: 'high',
          notification: {
            channelId: 'ratings',
          },
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
            },
          },
        },
      });
      
      console.log(`Notification sent to user ${userDoc.id}`);
    } catch (error) {
      console.error(`Failed to send notification: ${error}`);
      
      // If token is invalid, remove it
      if ((error as any).code === 'messaging/invalid-registration-token' ||
          (error as any).code === 'messaging/registration-token-not-registered') {
        await userDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
      }
    }
  });

// Weekly summary notification
export const sendWeeklySummary = functions.pubsub
  .schedule('0 9 * * 1') // Every Monday at 9 AM
  .timeZone('Africa/Accra')
  .onRun(async (context) => {
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    // Get all users with FCM tokens
    const usersSnapshot = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();
    
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const fcmToken = userDoc.data().fcmToken;
      
      // Get user's trips this week
      const tripsSnapshot = await db.collection('trips')
        .where('userId', '==', userId)
        .where('startTime', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
        .get();
      
      const tripCount = tripsSnapshot.size;
      
      if (tripCount === 0) continue; // No activity
      
      const totalDistance = tripsSnapshot.docs.reduce(
        (sum, doc) => sum + (doc.data().distance || 0), 
        0
      );
      
      const notification: NotificationPayload = {
        title: '📊 Your Weekly Summary',
        body: `You made ${tripCount} trips covering ${Math.round(totalDistance)} km this week!`,
        data: {
          type: 'weekly_summary',
        },
      };
      
      try {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: notification.data,
        });
      } catch (error) {
        console.error(`Failed to send summary to ${userId}: ${error}`);
      }
    }
  });
```

---

## 📤 Main Index Export

```typescript
// src/index.ts
export { onRatingCreated } from './ratings/onRatingCreated';
export { calculateDailyLeaderboards } from './leaderboards/calculateLeaderboards';
export { cleanupOldData } from './maintenance/cleanupOldData';
export { onDriverRated, sendWeeklySummary } from './notifications/sendAlerts';
```

---

## 🚀 Deployment

### Development Testing

```bash
cd functions
npm run build
firebase emulators:start --only functions,firestore
```

### Deploy to Production

```bash
firebase deploy --only functions
```

### View Logs

```bash
firebase functions:log
```

---

## ⚠️ Cost Considerations

| Function | Trigger | Estimated Invocations | Cost Factor |
|----------|---------|----------------------|-------------|
| `onRatingCreated` | Per rating | ~1000/day | Low |
| `calculateDailyLeaderboards` | Daily scheduled | 1/day | Low |
| `cleanupOldData` | Weekly scheduled | 1/week | Very Low |
| `onDriverRated` | Per rating (if registered) | ~100/day | Very Low |
| `sendWeeklySummary` | Weekly scheduled | 1/week | Low |

**Firebase Free Tier:** 125K invocations/month - should be sufficient for MVP.

---

## ✅ Function Deployment Checklist

- [ ] Functions tested locally with emulator
- [ ] Error handling for all edge cases
- [ ] Logging added for debugging
- [ ] Idempotency for write operations
- [ ] Rate limiting for callable functions
- [ ] Timeouts configured appropriately
- [ ] Memory allocation set correctly
- [ ] Region set to `europe-west1` (closest to Ghana)

---

**Remember:** Cloud Functions are the "server" for this app. They must be reliable, efficient, and cost-effective.
