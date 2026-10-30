import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../utils/constants.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderService _orderService = OrderService();

  String _selectedFilter = 'All Orders';
  final Set<String> _savingOrders = <String>{};

  static const Map<String, String?> _filters = <String, String?>{
    'All Orders': null,
    'Pending': 'Pending',
    'Confirmed': 'Confirmed',
    'Processing': 'Processing',
    'Shipped': 'Shipped',
    'Delivered': 'Delivered',
    'Cancelled': 'Cancelled',
  };

  Future<void> _changeStatus({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    final key = '$userId/$orderId';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.pageBg,
        title: const Text(
          'Update order status?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Change order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)} to $status?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.pageBg,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _savingOrders.add(key));

    try {
      await _orderService.updateOrderStatus(
        userId: userId,
        orderId: orderId,
        newStatus: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $status.'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingOrders.remove(key));
      }
    }
  }

  String _date(dynamic value) {
    DateTime? date;

    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;

    if (date == null) return 'Date unavailable';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.teal.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'shipped':
        return Colors.indigo.shade400;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return Colors.red.shade400;
      default:
        return AppColors.textSecondary;
    }
  }

  List<String> _availableNextStatuses(String current) {
    return (OrderService.allowedTransitions[current] ?? <String>{}).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_orderService.isCurrentUserAdmin) {
      return const Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Center(
          child: Text(
            'Admin access required.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _orderService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load orders',
              message: snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];
          final selectedStatus = _filters[_selectedFilter];

          final docs = allDocs.where((doc) {
            if (selectedStatus == null) return true;

            return (doc.data()['status']?.toString() ?? 'Pending') ==
                selectedStatus;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 58,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: _filters.entries.map((entry) {
                    final selected = _selectedFilter == entry.key;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.key),
                        selected: selected,
                        selectedColor: AppColors.green.withValues(alpha: 0.18),
                        backgroundColor: AppColors.coverBg,
                        side: BorderSide(
                          color: selected ? AppColors.green : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          color: selected
                              ? AppColors.green
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedFilter = entry.key);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  '${docs.length} ${docs.length == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? _message(
                        icon: Icons.inbox_outlined,
                        title: 'No orders found',
                        message: _selectedFilter == 'All Orders'
                            ? 'New customer orders will appear here.'
                            : 'There are no orders with this status.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          // Expected path: users/{uid}/orders/{orderId}
                          final pathUserId = doc.reference.parent.parent?.id;
                          final userId =
                              data['userId']?.toString().isNotEmpty == true
                              ? data['userId'].toString()
                              : pathUserId ?? '';

                          final orderId = doc.id;
                          final key = '$userId/$orderId';
                          final status =
                              data['status']?.toString() ?? 'Pending';
                          final customer =
                              data['customerName']?.toString() ?? 'Customer';
                          final phone = data['phone']?.toString() ?? 'No phone';
                          final total =
                              (data['total'] as num?)?.toDouble() ?? 0;
                          final rawItems = data['items'];
                          final items = rawItems is List
                              ? rawItems
                              : <dynamic>[];

                          final quantity = items.fold<int>(0, (count, item) {
                            if (item is Map) {
                              return count +
                                  ((item['quantity'] as num?)?.toInt() ?? 0);
                            }
                            return count;
                          });

                          final nextStatuses = _availableNextStatuses(status);
                          final saving = _savingOrders.contains(key);

                          return Card(
                            color: AppColors.coverBg,
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: AppColors.pageBg,
                                        foregroundColor: AppColors.green,
                                        child: Icon(Icons.receipt_long_rounded),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _date(data['createdAt']),
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _statusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    customer,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phone,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Customer UID: ${userId.isEmpty ? 'Unavailable' : userId}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if ((data['address']?.toString() ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Delivery address: ${data['address']}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const Divider(
                                    height: 24,
                                    color: AppColors.border,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$quantity ${quantity == 1 ? 'book' : 'books'}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (items.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ...items.whereType<Map>().map((item) {
                                      final title =
                                          item['title']?.toString() ?? 'Book';
                                      final qty =
                                          (item['quantity'] as num?)?.toInt() ??
                                          0;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 5,
                                        ),
                                        child: Text(
                                          '• $title × $qty',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                  const SizedBox(height: 14),
                                  if (nextStatuses.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: nextStatuses.first,
                                            isExpanded: true,
                                            dropdownColor: AppColors.coverBg,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Change status to',
                                              labelStyle: const TextStyle(
                                                color: AppColors.textSecondary,
                                              ),
                                              filled: true,
                                              fillColor: AppColors.pageBg,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.border,
                                                ),
                                              ),
                                            ),
                                            items: nextStatuses.map((value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: saving || userId.isEmpty
                                                ? null
                                                : (value) {
                                                    if (value != null) {
                                                      _changeStatus(
                                                        userId: userId,
                                                        orderId: orderId,
                                                        status: value,
                                                      );
                                                    }
                                                  },
                                          ),
                                        ),
                                        if (saving) ...[
                                          const SizedBox(width: 12),
                                          const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.green,
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  else
                                    Text(
                                      status == 'Delivered'
                                          ? 'Order completed'
                                          : 'No further status changes',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.green.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
