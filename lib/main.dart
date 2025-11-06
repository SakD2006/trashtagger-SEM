import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trashtagger/core/services/auth_service.dart';
import 'package:trashtagger/core/shared_widgets/home_screen.dart';
import 'package:trashtagger/features/0_auth/screens/login_screen.dart'; // Your login screen
import 'firebase_options.dart';
import 'package:trashtagger/utils/theme.dart';
import 'package:trashtagger/utils/routes.dart';
import 'package:trashtagger/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: routes,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // 1. If connection is active and we have a user, they are logged in.
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const HomeScreen(); // Show the main app screen with bottom navigation
          }
          // 2. If no user data, they are logged out.
          return const LoginScreen(); // Show the login screen
        }

        // 3. While checking, show a loading indicator.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
