/**
 * Stub service for push notifications using Firebase Cloud Messaging (FCM).
 * Will log to console for the hackathon but can be wired up to firebase-admin later.
 */

export const sendPushNotification = async (userId: string, title: string, body: string, data?: any): Promise<void> => {
    console.log(`\n🔔 [PUSH NOTIFICATION - User ${userId}]`);
    console.log(`   Title: ${title}`);
    console.log(`   Body:  ${body}\n`);
    // Example future integration:
    // const user = getUserById(userId);
    // if (user.fcm_token) {
    //    admin.messaging().send({ token: user.fcm_token, notification: { title, body }, data });
    // }
};
