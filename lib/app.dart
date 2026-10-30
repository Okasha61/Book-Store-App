import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/admin/admin_shell.dart';
import 'screens/main/main_screen.dart';
import 'services/admin_service.dart';

class BookStoreApp extends StatelessWidget {
  const BookStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF65E572);

    return MaterialApp(
      title: 'Book Store App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF00100E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
          primary: green,
          surface: const Color(0xFF00100E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00100E),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0C1B21),
          hintStyle: const TextStyle(color: Colors.white60),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2B424C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2B424C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF00100E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF65E572)),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Color(0xFF00100E),
            body: Center(
              child: Text(
                'Unable to check your login status.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null && user.uid == AdminService.adminUid) {
          return const AdminShell();
        }

        // Guests can browse books; protected actions ask them to log in.
        return const MainScreen();
      },
    );
  }
}
