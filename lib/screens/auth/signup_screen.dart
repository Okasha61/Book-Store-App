import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';

const _green = Color(0xFF65E572);
const _background = Color(0xFF00100E);
const _field = Color(0xFF0C1B21);
const _border = Color(0xFF2B424C);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _acceptedTerms = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate() || _loading) return;

    if (!_acceptedTerms) {
      _message('Please accept the Terms & Conditions.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
      );

      if (!mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
      if (navigator.canPop()) navigator.pop();
    } catch (error) {
      if (!mounted) return;
      _message(_error(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _socialLogin(bool google) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      if (google) {
        await _auth.signInWithGoogle();
      } else {
        await _auth.signInWithFacebook();
      }

      if (!mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
      if (navigator.canPop()) navigator.pop();
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
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email.';
        case 'weak-password':
          return 'Use a stronger password.';
        case 'network-request-failed':
          return 'Check your internet connection.';
      }

      return error.message ?? 'Signup failed. Please try again.';
    }

    return 'Could not create your account. Please try again.';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/signup.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: _background),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _background.withValues(alpha: 0.22),
                  _background.withValues(alpha: 0.88),
                  _background,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _brand(),
                        const SizedBox(height: 25),
                        const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 34,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: 'Create Your '),
                              TextSpan(
                                text: 'Account',
                                style: TextStyle(color: _green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join BookStore and start your journey\nwith thousands of books.',
                          style: TextStyle(
                            color: Color(0xFFD2DEE3),
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _input(
                          _name,
                          'Full Name',
                          Icons.person_outline,
                          validator: (value) {
                            final name = value?.trim() ?? '';

                            if (name.isEmpty) {
                              return 'Name is required.';
                            }
                            if (name.length < 2) {
                              return 'Enter at least 2 characters.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _input(
                          _email,
                          'Email Address',
                          Icons.mail_outline,
                          keyboard: TextInputType.emailAddress,
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
                        const SizedBox(height: 12),
                        _input(
                          _phone,
                          'Phone Number (Optional)',
                          Icons.phone_outlined,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          _password,
                          'Password',
                          Icons.lock_outline,
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required.';
                            }
                            if (value.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                                !RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Include letters and numbers.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _input(
                          _confirm,
                          'Confirm Password',
                          Icons.lock_outline,
                          obscure: _hideConfirm,
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _hideConfirm = !_hideConfirm),
                            icon: Icon(
                              _hideConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password.';
                            }
                            if (value != _password.text) {
                              return 'Passwords do not match.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: _green,
                              checkColor: Colors.black,
                              onChanged: (value) => setState(
                                () => _acceptedTerms = value ?? false,
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'I agree to the Terms & Conditions and Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _button('Sign Up', _signup),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: _border)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            Expanded(child: Divider(color: _border)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _social(
                          'G',
                          'Continue with Google',
                          () => _socialLogin(true),
                        ),
                        const SizedBox(height: 10),
                        _social(
                          'f',
                          'Continue with Facebook',
                          () => _socialLogin(false),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    ),
                              child: const Text(
                                'Login',
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
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.menu_book_rounded, size: 44, color: _green),
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
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

  Widget _input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8C5D1)),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: suffix,
        filled: true,
        fillColor: _field.withValues(alpha: 0.90),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: _green),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback action) {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF55E86B), Color(0xFF7BE779)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : action,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.black)
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    SizedBox(width: 14),
                    Icon(Icons.arrow_forward),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _social(String letter, String label, VoidCallback action) {
    return OutlinedButton(
      onPressed: _loading ? null : action,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(45),
        foregroundColor: Colors.white,
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: letter == 'G'
                ? Colors.white
                : const Color(0xFF1877F2),
            child: Text(
              letter,
              style: TextStyle(
                color: letter == 'G' ? Colors.red : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(label, style: const TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
