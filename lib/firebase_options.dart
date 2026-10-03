import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyDemoApiKeyForWebInitialization123',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '1:100000000000:web:demo123456789',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '100000000000',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'restaurant-queue-app-demo',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? 'restaurant-queue-app-demo.firebaseapp.com',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'restaurant-queue-app-demo.appspot.com',
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyDemoApiKeyForAndroid123',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '1:100000000000:android:demo123456789',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '100000000000',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'restaurant-queue-app-demo',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'restaurant-queue-app-demo.appspot.com',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyDemoApiKeyForIos123',
        appId: dotenv.env['FIREBASE_APP_ID'] ?? '1:100000000000:ios:demo123456789',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '100000000000',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? 'restaurant-queue-app-demo',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 'restaurant-queue-app-demo.appspot.com',
        iosBundleId: 'com.example.restaurantQueueApp',
      );
}
