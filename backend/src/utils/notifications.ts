

export const sendPushNotification = async (userId: string, title: string, body: string, data?: any): Promise<void> => {
    console.log(`\n🔔 [PUSH NOTIFICATION - User ${userId}]`);
    console.log(`   Title: ${title}`);
    console.log(`   Body:  ${body}\n`);

};
