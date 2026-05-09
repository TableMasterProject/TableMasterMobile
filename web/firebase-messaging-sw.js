importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBdcFkbdegYPyZIYjeW7oZ4hGq8NqifLmQ',
  appId: '1:739801589159:web:621e5abd2da15b1bf60282',
  messagingSenderId: '739801589159',
  projectId: 'tablemaster-6e5d1',
  authDomain: 'tablemaster-6e5d1.firebaseapp.com',
  storageBucket: 'tablemaster-6e5d1.firebasestorage.app',
  measurementId: 'G-WPMKX8XZXE',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const notification = message.notification || {};
  const title = notification.title || message.data?.title || 'Table Master';
  const options = {
    body: notification.body || message.data?.body || '',
    icon: '/icons/Icon-192.png',
    data: message.data || {},
  };

  self.registration.showNotification(title, options);
});
