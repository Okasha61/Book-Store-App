import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../utils/constants.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  final String orderId;
  final Map<String, dynamic> orderData;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _cancelling = false;

  static const Color _cardColor = Color(0xE6101F1D);
  static const Color _secondaryText = Color(0xFFB5C4BF);
  static const Color _borderColor = Color(0xFF304440);

  String _formatDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) return 'Date unavailable';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} at $hour:$minute';
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'confirmed':
        return Colors.tealAccent;
      case 'processing':
        return Colors.lightBlueAccent;
      case 'shipped':
        return Colors.deepPurpleAccent.shade100;
      case 'delivered':
        return AppColors.lime;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return _secondaryText;
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF142421),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _borderColor),
        ),
        title: const Text(
          'Cancel this order?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You can cancel only before the order is shipped.',
          style: TextStyle(color: _secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Keep order',
              style: TextStyle(color: AppColors.lime),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);

    try {
      await OrderService().cancelMyOrder(widget.orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: Color(0xFF173B2B),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.headerDark,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.lime),
        backgroundColor: AppColors.headerDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
          const ColoredBox(color: Color(0xCC00100E)),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: OrderService().watchMyOrder(widget.orderId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Unable to load latest order details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.lime),
                );
              }

              final liveData = snapshot.data?.data() ?? widget.orderData;
              final status = liveData['status']?.toString() ?? 'Pending';

              final rawItems = liveData['items'];
              final items = rawItems is List
                  ? rawItems
                        .whereType<Map>()
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList()
                  : <Map<String, dynamic>>[];

              final canCancel = <String>{
                'pending',
                'confirmed',
                'processing',
              }.contains(status.toLowerCase());

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Order Number'),
                        const SizedBox(height: 5),
                        SelectableText(
                          widget.orderId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Order Date'),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(liveData['createdAt']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Order Status'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _statusColor(
                                status,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (canCancel) ...[
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _cancelling ? null : _cancelOrder,
                              icon: _cancelling
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.redAccent,
                                      ),
                                    )
                                  : const Icon(Icons.cancel_outlined),
                              label: Text(
                                _cancelling ? 'Cancelling...' : 'Cancel Order',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Books Ordered'),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _panel(
                      child: const Text(
                        'No item details available for this order.',
                        style: TextStyle(color: _secondaryText),
                      ),
                    )
                  else
                    ...items.map((item) {
                      final title = item['title']?.toString() ?? 'Book';
                      final author = item['author']?.toString() ?? '';
                      final imageUrl = item['imageUrl']?.toString() ?? '';
                      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                      final price = item['price'];
                      final itemTotal =
                          item['itemTotal'] ??
                          ((price is num ? price : 0) * quantity);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 76,
                                  height: 100,
                                  child: imageUrl.trim().isEmpty
                                      ? _bookPlaceholder()
                                      : Image.network(
                                          imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              _bookPlaceholder(),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (author.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        'By $author',
                                        style: const TextStyle(
                                          color: _secondaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Qty: $quantity',
                                      style: const TextStyle(
                                        color: _secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _money(itemTotal),
                                      style: const TextStyle(
                                        color: AppColors.lime,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  _sectionTitle('Delivery Details'),
                  const SizedBox(height: 12),
                  _infoCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Customer',
                    value: liveData['customerName']?.toString() ?? '',
                  ),
                  _infoCard(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    value: liveData['phone']?.toString() ?? '',
                  ),
                  _infoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Address',
                    value: liveData['address']?.toString() ?? '',
                  ),
                  _infoCard(
                    icon: Icons.payment_rounded,
                    title: 'Payment Method',
                    value:
                        liveData['paymentMethod']?.toString() ??
                        'Cash on Delivery',
                  ),
                  const SizedBox(height: 22),
                  _panel(
                    child: Column(
                      children: [
                        _priceRow('Subtotal', _money(liveData['subtotal'])),
                        const SizedBox(height: 12),
                        _priceRow(
                          'Delivery Fee',
                          _money(liveData['deliveryFee']),
                        ),
                        const Divider(height: 28, color: _borderColor),
                        _priceRow(
                          'Total',
                          _money(liveData['total']),
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(color: _secondaryText));
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _bookPlaceholder() {
    return Container(
      color: const Color(0xFF20332E),
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 36,
        color: AppColors.lime,
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.lime),
        title: Text(
          title,
          style: const TextStyle(color: _secondaryText, fontSize: 12),
        ),
        subtitle: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : _secondaryText,
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppColors.lime : Colors.white,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
