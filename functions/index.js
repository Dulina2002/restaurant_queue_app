const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Auth Trigger: Automatically create user document in Firestore on registration
 */
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const userRef = db.collection("users").doc(user.uid);
  const doc = await userRef.get();

  if (!doc.exists) {
    await userRef.set({
      id: user.uid,
      email: user.email || "",
      full_name: user.displayName || "User",
      role: "customer",
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});

/**
 * 2. Firestore Trigger: Auto-recalculate queue positions and wait times
 * whenever a party is seated or cancels.
 */
exports.onQueueStatusChanged = functions.firestore
    .document("queue_entries/{queueId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Only recalculate when status transitions to seated or cancelled
      if (beforeData.status !== afterData.status &&
          (afterData.status === "seated" || afterData.status === "cancelled")) {
        const restaurantId = afterData.restaurant_id;
        const waitingSnapshot = await db
            .collection("queue_entries")
            .where("restaurant_id", "==", restaurantId)
            .where("status", "==", "waiting")
            .orderBy("created_at", "asc")
            .get();

        const batch = db.batch();
        let pos = 1;
        waitingSnapshot.forEach((doc) => {
          batch.update(doc.ref, {
            position: pos,
            estimated_wait_minutes: pos * 5,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          pos++;
        });

        // Update restaurant waitlist count
        const restaurantRef = db.collection("restaurants").doc(restaurantId);
        batch.set(
            restaurantRef,
            {
              waitlist_count: waitingSnapshot.docs.length,
              est_wait: waitingSnapshot.docs.length === 0 ?
              "Direct Seating" :
              `${waitingSnapshot.docs.length * 5} min wait`,
            },
            {merge: true},
        );

        await batch.commit();
      }
    });

/**
 * 3. Callable Cloud Function: Securely set user role (Admin only)
 */
exports.setUserRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated.",
    );
  }

  // Check caller role
  const callerDoc = await db.collection("users").doc(context.auth.uid).get();
  if (!callerDoc.exists || callerDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only Administrators can change user roles.",
    );
  }

  const {targetUserId, newRole} = data;
  if (!targetUserId || !newRole) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "targetUserId and newRole are required.",
    );
  }

  await db.collection("users").doc(targetUserId).update({
    role: newRole,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {success: true, message: `User role updated to ${newRole}`};
});
