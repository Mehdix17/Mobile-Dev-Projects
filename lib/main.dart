import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'shared/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously if no user is signed in
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Failed to sign in anonymously: $e');
    debugPrint('App will continue without authentication.');
    debugPrint('Please enable Firebase Authentication in Firebase Console:');
    debugPrint('1. Go to Firebase Console');
    debugPrint('2. Select Authentication');
    debugPrint('3. Enable Email/Password and Anonymous sign-in methods');
  }

  // Initialize notifications
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: CardlyApp(),
    ),
  );
}
