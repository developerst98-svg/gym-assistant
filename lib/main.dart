import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase/firebase_options.dart';
import 'main_pages/role_wrapper.dart';
import 'pages/auth/login.dart';
import 'theme.dart';
import 'main_pages/import_json_workout.dart';
import 'main_pages/import_json_workout_2.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await importWorkouts();
  // await importGymExercises();

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      theme: appThemeDark,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!snapshot.hasData) {
            return const LoginPage();
          }
          return const RoleWrapper();
        },
      ),
    );
  }
}
