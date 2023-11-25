// lib/main.dart

// Main
import 'package:flutter/material.dart';

// Controllers
import 'controller/diary_controller.dart';

// Views
import 'view/diary_entry_view.dart';
import 'view/diary_log_view.dart';
import 'view/login_view.dart';
import 'view/notification_view.dart';

// FireBase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance
      .signOut(); // Incase did not signout before closing app

  runApp(DiaryApp());
}

class DiaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dear Diary',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            return DiaryLogWrapper(); // User is signed in
          } else {
            return SignInView(); // User is not signed in, show SignInView
          }
        },
      ),
      routes: {
        '/setNotification': (context) => SetNotificationView(),
        '/addEntry': (context) => DiaryEntryWrapper(),
      },
    );
  }
}

class DiaryLogWrapper extends StatefulWidget {
  @override
  _DiaryLogWrapperState createState() => _DiaryLogWrapperState();
}

class _DiaryLogWrapperState extends State<DiaryLogWrapper> {
  DiaryController controller = DiaryController();

  @override
  void initState() {
    super.initState();
    // Firebase Firestore initialization or other setup if necessary
  }

  @override
  Widget build(BuildContext context) {
    // Firebase Firestore related UI code if necessary
    return DiaryLogView(controller: controller);
  }
}

class DiaryEntryWrapper extends StatefulWidget {
  @override
  _DiaryEntryWrapperState createState() => _DiaryEntryWrapperState();
}

class _DiaryEntryWrapperState extends State<DiaryEntryWrapper> {
  DiaryController controller = DiaryController();

  @override
  void initState() {
    super.initState();
    // Firebase Firestore initialization or other setup if necessary
  }

  @override
  Widget build(BuildContext context) {
    // Firebase Firestore related UI code if necessary
    return DiaryEntryView(controller: controller);
  }
}
