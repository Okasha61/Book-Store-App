import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';

Future<bool> requireLogin(
  BuildContext context, {
  String action = 'continue',
}) async {
  if (FirebaseAuth.instance.currentUser != null) return true;

  final shouldLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(
        Icons.lock_outline_rounded,
        color: Color(0xFF65E572),
        size: 36,
      ),
      title: const Text('Login Required'),
      content: Text('Please log in or create an account to $action.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Login / Sign Up'),
        ),
      ],
    ),
  );

  if (shouldLogin != true || !context.mounted) return false;

  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const LoginScreen()));

  return FirebaseAuth.instance.currentUser != null;
}
