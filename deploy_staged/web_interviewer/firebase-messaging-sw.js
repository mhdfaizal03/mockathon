importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

// Initialize the Firebase app in the service worker by passing in any details.
// TODO: Replace with your project's config object from the Firebase Console.
firebase.initializeApp({
  apiKey: "AIzaSyBZRN6VmbUDLqJ5ei66lLcJpBdku5XlS0w",
  authDomain: "mockathon-dc9a3.firebaseapp.com",
  projectId: "mockathon-dc9a3",
  storageBucket: "mockathon-dc9a3.firebasestorage.app",
  messagingSenderId: "707194801773",
  appId: "1:707194801773:web:cb3d57a78799a20e88b964"
});

const messaging = firebase.messaging();

// Optional: Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
