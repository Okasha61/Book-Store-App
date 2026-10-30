import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../utils/constants.dart';
import '../../utils/login_prompt.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const Color _primaryColor = AppColors.green;
  static const Color _cardColor = Color(0xE6101F1D);
  static const Color _borderColor = Color(0xFF30423E);

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Cart',
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
            child: StreamBuilder<List<CartItemModel>>(
              stream: cartService.getCartItems(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _message(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unable to load cart',
                    description:
                        'Please check your connection and Firestore rules.',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  if (FirebaseAuth.instance.currentUser == null) {
                    return _message(
                      icon: Icons.lock_outline_rounded,
                      title: 'Login to use your cart',
                      description:
                          'Sign in to add books and continue to checkout.',
                      buttonText: 'Login / Sign Up',
                      onPressed: () async {
                        await requireLogin(context, action: 'use your cart');
                      },
                    );
                  }

                  return _message(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your cart is empty',
                    description:
                        'Browse books and add your favourites to the cart.',
                    buttonText: 'Continue Shopping',
                    onPressed: () => Navigator.of(context).pop(),
                  );
                }

                final total = items.fold<double>(
                  0,
                  (sum, item) => sum + item.totalPrice,
                );

                final totalQuantity = items.fold<int>(
                  0,
                  (sum, item) => sum + item.quantity,
                );

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$totalQuantity ${totalQuantity == 1 ? 'book' : 'books'} in your cart',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _confirmClearCart(context, cartService),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Clear cart'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent.shade100,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return _CartItemCard(
                            item: item,
                            onIncrease: () => _changeQuantity(
                              context,
                              cartService,
                              item,
                              item.quantity + 1,
                            ),
                            onDecrease: () => _changeQuantity(
                              context,
                              cartService,
                              item,
                              item.quantity - 1,
                            ),
                            onRemove: () =>
                                _removeItem(context, cartService, item),
                          );
                        },
                      ),
                    ),
                    _buildSummary(
                      context,
                      items: items,
                      total: total,
                      itemCount: totalQuantity,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context, {
    required List<CartItemModel> items,
    required double total,
    required int itemCount,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xF00E1A19),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ),
              Text(
                'Rs. ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Delivery',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
              Text(
                'Calculated at checkout',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const Divider(height: 24, color: _borderColor),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Rs. ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.lime,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () async {
                final loggedIn = await requireLogin(
                  context,
                  action: 'proceed to checkout',
                );

                if (!context.mounted || !loggedIn) return;

                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CheckoutScreen(items: items),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: const Color(0xFF00100E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(
                'Proceed to Checkout ($itemCount)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _message({
    required IconData icon,
    required String title,
    required String description,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 68, color: AppColors.lime.withValues(alpha: 0.85)),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: const Color(0xFF00100E),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _changeQuantity(
    BuildContext context,
    CartService service,
    CartItemModel item,
    int quantity,
  ) async {
    try {
      await service.updateQuantity(item, quantity);
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  static Future<void> _removeItem(
    BuildContext context,
    CartService service,
    CartItemModel item,
  ) async {
    try {
      await service.removeFromCart(item.bookId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} removed from cart.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  static Future<void> _confirmClearCart(
    BuildContext context,
    CartService service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF10201D),
        title: const Text('Clear cart?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will remove all books from your cart.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.lime),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await service.clearCart();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart cleared.')));
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error);
    }
  }

  static void _showError(BuildContext context, Object error) {
    final message = error is StateError
        ? error.message.toString()
        : 'Something went wrong. Please try again.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  static const Color _primaryColor = AppColors.green;
  static const Color _borderColor = Color(0xFF30423E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE6101F1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 88,
              height: 118,
              child: item.imageUrl.trim().isEmpty
                  ? _coverPlaceholder()
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _coverPlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _quantityButton(
                      icon: Icons.remove_rounded,
                      onPressed: onDecrease,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add_rounded,
                      onPressed: onIncrease,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Remove item',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent.shade100,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Item total: Rs. ${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: const Color(0xFF253B34),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(icon, size: 18, color: AppColors.lime),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: AppColors.coverBg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 38,
        color: AppColors.green,
      ),
    );
  }
}
