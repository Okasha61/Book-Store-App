import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../widgets/home_header.dart';
import 'order_details_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static const String _backgroundImage = 'assets/images/bottomls.jpg';

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade800;
      case 'confirmed':
        return Colors.teal.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'shipped':
        return Colors.indigo.shade700;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              _backgroundImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Orders background image error: $error');

                return const ColoredBox(color: AppColors.pageBg);
              },
            ),
          ),

          // Very light overlay so the image remains visible.
          Positioned.fill(
            child: Container(color: AppColors.pageBg.withValues(alpha: 0.10)),
          ),

          // Orders content
          SafeArea(
            child: Column(
              children: [
                const HomeHeader(onSearch: _ignoreSearch),
                Expanded(
                  child: StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, authSnapshot) {
                      if (authSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !authSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        );
                      }

                      final user = authSnapshot.data;

                      if (user == null) {
                        return _buildMessage(
                          icon: Icons.lock_outline_rounded,
                          title: 'Login to view your orders',
                          message:
                              'Sign in to see your orders and track their status.',
                        );
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        key: ValueKey(user.uid),
                        stream: OrderService().getMyOrders(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildMessage(
                              icon: Icons.cloud_off_outlined,
                              title: 'Unable to load orders',
                              message:
                                  'Please check your internet connection and '
                                  'Firestore security rules.',
                            );
                          }

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.green,
                              ),
                            );
                          }

                          final documents = snapshot.data?.docs ?? [];

                          if (documents.isEmpty) {
                            return _buildMessage(
                              icon: Icons.receipt_long_outlined,
                              title: 'No orders yet',
                              message:
                                  'Your placed orders will appear here. '
                                  'Explore the bookstore and find your next read.',
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                            itemCount: documents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final document = documents[index];
                              final data = document.data();

                              final status =
                                  data['status']?.toString() ?? 'Pending';

                              final total =
                                  (data['total'] as num?)?.toDouble() ?? 0;

                              final rawItems = data['items'];
                              final items = rawItems is List
                                  ? rawItems
                                  : <dynamic>[];

                              final itemCount = items.fold<int>(0, (
                                count,
                                item,
                              ) {
                                if (item is Map) {
                                  return count +
                                      ((item['quantity'] as num?)?.toInt() ??
                                          0);
                                }

                                return count;
                              });

                              return Card(
                                color: Colors.white,
                                elevation: 2,
                                shadowColor: Colors.black.withValues(
                                  alpha: 0.12,
                                ),
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => OrderDetailsScreen(
                                          orderId: document.id,
                                          orderData: data,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor:
                                                  AppColors.coverBg,
                                              foregroundColor: AppColors.green,
                                              child: Icon(
                                                Icons.receipt_long_rounded,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Order #${document.id.length > 8 ? document.id.substring(0, 8) : document.id}',
                                                    style: const TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    _formatDate(
                                                      data['createdAt'],
                                                    ),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _statusColor(
                                                  status,
                                                ).withValues(alpha: 0.10),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                status,
                                                style: TextStyle(
                                                  color: _statusColor(status),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        Text(
                                          '$itemCount ${itemCount == 1 ? 'book' : 'books'}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const Divider(
                                          height: 24,
                                          color: AppColors.border,
                                        ),
                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Order Total',
                                                style: TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              'Rs. ${total.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: AppColors.green,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: AppColors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: AppColors.green,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _ignoreSearch(String query) {}

  Widget _buildMessage({
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
              size: 68,
              color: AppColors.green.withValues(alpha: 0.95),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
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
