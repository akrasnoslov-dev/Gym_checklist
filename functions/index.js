const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

initializeApp();

const recentAuthenticationWindowSeconds = 5 * 60;
const maximumClockSkewSeconds = 60;

exports.deleteAccount = onCall(
  { region: "us-central1", timeoutSeconds: 120, memory: "256MiB" },
  async (request) => {
    const uid = request.auth?.uid;
    const authenticatedAt = Number(request.auth?.token?.auth_time);
    const nowSeconds = Math.floor(Date.now() / 1000);

    if (!uid) {
      throw new HttpsError("unauthenticated", "Authentication is required.");
    }
    if (
      !Number.isFinite(authenticatedAt) ||
      authenticatedAt > nowSeconds + maximumClockSkewSeconds ||
      nowSeconds - authenticatedAt > recentAuthenticationWindowSeconds
    ) {
      throw new HttpsError("failed-precondition", "Recent authentication is required.");
    }

    const database = getFirestore();
    await database.recursiveDelete(database.collection("users").doc(uid));
    await getAuth().deleteUser(uid);
    return { deleted: true };
  }
);
