import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../utils/login_prompt.dart';
import '../admin/admin_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _backgroundColor = Color(0xFF00100E);
  static const Color _primaryColor = Color(0xFF65E572);
  static const Color _cardColor = Color(0xFF0C1B21);
  static const Color _borderColor = Color(0xFF2B424C);
  static const Color _textColor = Colors.white;
  static const Color _secondaryTextColor = Color(0xFFB0BEC5);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  String _email = '';
  String? _loadedUid;

  StreamSubscription<User?>? _authSubscription;

  bool get _isAdmin => AdminService().isAdmin;

  void _openAdminPanel() {
    if (!_isAdmin) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AdminShell()));
  }

  @override
  void initState() {
    super.initState();

    _loadProfile();

    _authSubscription = FirebaseAuth.instance.authStateChanges().skip(1).listen(
      (user) {
        if (!mounted) return;

        if (user == null) {
          _nameController.clear();
          _phoneController.clear();
          _addressController.clear();

          setState(() {
            _email = '';
            _loadedUid = null;
            _isLoading = false;
          });
        } else if (_loadedUid != user.uid) {
          setState(() => _isLoading = true);
          _loadProfile();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _loadedUid = user.uid;

    try {
      final profile = await _profileService.getProfile();

      if (!mounted) return;

      _nameController.text =
          (profile?['name'] as String?) ?? user.displayName ?? '';

      _phoneController.text = (profile?['phone'] as String?) ?? '';
      _addressController.text = (profile?['address'] as String?) ?? '';
      _email = user.email ?? '';
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _profileService.saveProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not update your profile.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await AuthService().signOut();

      if (!mounted) return;

      _nameController.clear();
      _phoneController.clear();
      _addressController.clear();

      setState(() {
        _email = '';
        _loadedUid = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have been logged out.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not log out: $error')));
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  Widget _backgroundBody(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/bottomls.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: _backgroundColor);
          },
        ),
        const ColoredBox(color: Color(0x6600100E)),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: const TextStyle(color: _secondaryTextColor),
      hintStyle: const TextStyle(color: Colors.white38),
      helperStyle: const TextStyle(color: _secondaryTextColor),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: _cardColor.withValues(alpha: 0.95),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _cardColor.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 46,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome, Guest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Log in or create an account to manage your profile, '
                  'wishlist and orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await requireLogin(
                        context,
                        action: 'access your profile',
                      );

                      if (mounted &&
                          FirebaseAuth.instance.currentUser != null) {
                        setState(() => _isLoading = true);
                        await _loadProfile();
                      }
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: const Text(
                      'Login / Sign Up',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: _backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _cardColor.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primaryColor.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: _primaryColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your Details',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep your contact and delivery information '
                            'up to date.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _secondaryTextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: _textColor),
                            decoration: _inputDecoration(
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) =>
                                _requiredValidator(value, 'Name'),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            key: ValueKey(_email),
                            initialValue: _email,
                            readOnly: true,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _secondaryTextColor),
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.email_outlined,
                              helper: 'Email cannot be changed here.',
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: _textColor),
                            decoration: _inputDecoration(
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              hint: '03XXXXXXXXX',
                            ),
                            validator: (value) =>
                                _requiredValidator(value, 'Phone number'),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _addressController,
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(color: _textColor),
                            decoration: _inputDecoration(
                              label: 'Delivery Address',
                              icon: Icons.location_on_outlined,
                              hint: 'House, street, area, city',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) =>
                                _requiredValidator(value, 'Address'),
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _isSaving ? null : _saveProfile,
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _backgroundColor,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _isSaving ? 'Saving...' : 'Save Profile',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: _backgroundColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          // Show this option only to the admin account.
                          if (_isAdmin) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _openAdminPanel,
                                icon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                ),
                                label: const Text('Back to Admin Panel'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _primaryColor,
                                  side: const BorderSide(color: _primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _isLoggingOut ? null : _logout,
                            icon: _isLoggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primaryColor,
                                    ),
                                  )
                                : const Icon(Icons.logout_rounded),
                            label: Text(
                              _isLoggingOut ? 'Logging out...' : 'Logout',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: const BorderSide(color: _borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          foregroundColor: _textColor,
          elevation: 0,
          title: const Text(
            'My Profile',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: _backgroundBody(_buildGuestView()),
      );
    }

    if (_loadedUid != user.uid && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            FirebaseAuth.instance.currentUser?.uid == user.uid &&
            _loadedUid != user.uid) {
          setState(() => _isLoading = true);
          _loadProfile();
        }
      });
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _backgroundBody(_buildProfileForm()),
    );
  }
}
