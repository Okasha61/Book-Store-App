import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item_model.dart';
import '../../services/order_service.dart';
import '../../services/profile_service.dart';
import '../../utils/constants.dart';
import '../../utils/login_prompt.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.items});

  final List<CartItemModel> items;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _primaryColor = AppColors.green;
  static const Color _cardColor = Color(0xE6101F1D);
  static const Color _borderColor = Color(0xFF30423E);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _orderService = OrderService();
  final _profileService = ProfileService();

  bool _isSubmitting = false;
  bool _isLoadingProfile = true;

  // Existing delivery fee preserved.
  static const double _deliveryFee = 200;

  double get _subtotal =>
      widget.items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  double get _total => _subtotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    try {
      final profile = await _profileService.getProfile();

      if (!mounted) return;

      if (profile != null) {
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = (profile['name'] as String?) ?? '';
        }

        if (_phoneController.text.trim().isEmpty) {
          _phoneController.text = (profile['phone'] as String?) ?? '';
        }

        if (_addressController.text.trim().isEmpty) {
          _addressController.text = (profile['address'] as String?) ?? '';
        }
      }
    } catch (_) {
      // Checkout remains usable if profile data cannot be loaded.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_isSubmitting) return;

    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(context, action: 'place your order');

      if (!loggedIn || !mounted) return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final orderId = await _orderService.placeOrder(
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        items: widget.items,
        deliveryFee: _deliveryFee,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF10201D),
          icon: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.lime,
            size: 52,
          ),
          title: const Text(
            'Order placed successfully!',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Your order has been saved.\n'
            'Order ID: $orderId\n'
            'Payment: Cash on Delivery',
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: const Color(0xFF00100E),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error is StateError
          ? error.message.toString()
          : 'Could not place your order. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerDark,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bottomls.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: AppColors.headerDark);
            },
          ),
          const ColoredBox(color: Color(0xB300100E)),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionCard(
                    title: 'Delivery Details',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      children: [
                        if (_isLoadingProfile) ...[
                          const LinearProgressIndicator(
                            color: _primaryColor,
                            backgroundColor: _borderColor,
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppColors.lime,
                          decoration: _inputDecoration(
                            label: 'Full name',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'Please enter your full name.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppColors.lime,
                          decoration: _inputDecoration(
                            label: 'Phone number',
                            hint: '03XXXXXXXXX',
                            icon: Icons.phone_outlined,
                          ),
                          validator: (value) {
                            final phone = value?.trim() ?? '';

                            if (phone.length < 7) {
                              return 'Please enter a valid phone number.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: AppColors.lime,
                          decoration: _inputDecoration(
                            label: 'Complete delivery address',
                            icon: Icons.home_outlined,
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 10) {
                              return 'Please enter your complete address.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Order Summary',
                    icon: Icons.receipt_long_outlined,
                    child: Column(
                      children: [
                        for (final item in widget.items) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.title} × ${item.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Rs. ${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Divider(color: _borderColor),
                        _priceRow('Subtotal', _subtotal),
                        const SizedBox(height: 8),
                        _priceRow('Delivery fee', _deliveryFee),
                        const Divider(height: 24, color: _borderColor),
                        _priceRow('Total', _total, isTotal: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xE6101F1D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: AppColors.lime,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay when your books are delivered.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _placeOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: const Color(0xFF00100E),
                        disabledBackgroundColor: _borderColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSubmitting
                            ? 'Placing Order...'
                            : 'Place Order • Rs. '
                                  '${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: AppColors.lime),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFF172723),
      contentPadding: const EdgeInsets.all(14),
      errorStyle: const TextStyle(color: Colors.redAccent),
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
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.lime),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.white : Colors.white70,
            ),
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 21 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.lime : Colors.white,
          ),
        ),
      ],
    );
  }
}
