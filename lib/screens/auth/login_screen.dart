import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

const _green = Color(0xFF65E572);
const _background = Color(0xFF00100E);
const _field = Color(0xFF0C1B21);
const _border = Color(0xFF2B424C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);

    try {
      await _auth.signIn(email: _email.text, password: _password.text);

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(bool google) async {
    if (_loading) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      if (google) {
        await _auth.signInWithGoogle();
      } else {
        await _auth.signInWithFacebook();
      }

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _message(_error(error));
    } catch (error) {
      if (!mounted) return;
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _error(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'This email is already registered with another sign-in method.';
        case 'popup-closed-by-user':
          return 'Sign-in window was closed. Please try again.';
        case 'popup-blocked':
          return 'Your browser blocked the sign-in popup. Allow popups and retry.';
        case 'cancelled-popup-request':
          return 'A sign-in request is already running. Please try again.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled in Firebase.';
        case 'unauthorized-domain':
          return 'This website domain is not authorized in Firebase Authentication.';
        case 'invalid-credential':
          return 'The sign-in credential is invalid or expired. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-email':
          return 'Please check your email and password.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Please choose a stronger password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        case 'web-storage-unsupported':
          return 'Browser storage is unavailable. Enable cookies and site storage.';
        case 'google-token-missing':
          return 'Google did not return a sign-in token. Please try again.';
        case 'facebook-token-missing':
          return 'Facebook did not return a sign-in token. Please try again.';
        case 'facebook-login-failed':
          return error.message ?? 'Facebook sign-in failed.';
        default:
          return error.message ?? 'Login failed. Please try again.';
      }
    }

    final message = error.toString().replaceFirst('Exception: ', '');

    if (message.contains('popup-closed-by-user')) {
      return 'Sign-in window was closed. Please try again.';
    }

    if (message.contains('popup-blocked')) {
      return 'Allow popups in your browser and try again.';
    }

    if (message.contains('FB is undefined')) {
      return 'Facebook web login is not configured correctly. Check Firebase Facebook provider settings.';
    }

    return message.isNotEmpty
        ? message
        : 'Login failed. Check your configuration and try again.';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: _background),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _background.withValues(alpha: 0.28),
                  _background.withValues(alpha: 0.90),
                  _background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 38, 24, 26),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brand(),
                        const SizedBox(height: 54),
                        _heading(),
                        const SizedBox(height: 34),
                        _input(
                          controller: _email,
                          hint: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Email is required.';
                            }

                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(email)) {
                              return 'Enter a valid email.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _input(
                          controller: _password,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: _hidePassword,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Password is required.'
                              : null,
                          onSubmitted: (_) => _login(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: _green),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _primaryButton('Login', _login),
                        const SizedBox(height: 26),
                        _divider(),
                        const SizedBox(height: 20),
                        _socialButton(
                          'Continue with Google',
                          'G',
                          () => _socialLogin(true),
                        ),
                        const SizedBox(height: 12),
                        _socialButton(
                          'Continue with Facebook',
                          'f',
                          () => _socialLogin(false),
                        ),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(color: _green),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand() => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/images/icon.jpg',
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book_rounded, color: _green, size: 48),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(text: 'Book'),
                  TextSpan(
                    text: 'Store',
                    style: TextStyle(color: _green),
                  ),
                ],
              ),
            ),
            Text(
              'Read More  •  Grow More',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _heading() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 35,
            height: 1.15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(text: 'Welcome '),
            TextSpan(
              text: 'Back!',
              style: TextStyle(color: _green),
            ),
          ],
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Log in to your account and continue\nyour reading journey.',
        style: TextStyle(color: Color(0xFFD2DEE3), fontSize: 16, height: 1.55),
      ),
    ],
  );

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8C5D1)),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffix,
        filled: true,
        fillColor: _field.withValues(alpha: 0.90),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _green, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback action) {
    return SizedBox(
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF55E86B), Color(0xFF7BE779)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : action,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 23,
                  width: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward, size: 23),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _divider() => const Row(
    children: [
      Expanded(child: Divider(color: _border)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          'or continue with',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      Expanded(child: Divider(color: _border)),
    ],
  );

  Widget _socialButton(String label, String letter, VoidCallback action) {
    return OutlinedButton(
      onPressed: _loading ? null : action,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: Colors.white,
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: letter == 'G'
                ? Colors.white
                : const Color(0xFF1877F2),
            child: Text(
              letter,
              style: TextStyle(
                color: letter == 'G' ? Colors.red : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 26),
        ],
      ),
    );
  }
}
