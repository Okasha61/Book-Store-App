import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _bg = Color(0xFF061116);
  static const _panel = Color(0xFF0B1A21);
  static const _border = Color(0xFF1B3039);
  static const _green = Color(0xFF22D66B);

  final _admin = AdminService();
  final _orders = OrderService();

  String _period = 'Last 7 Days';

  @override
  Widget build(BuildContext context) {
    if (!_admin.isAdmin) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Text(
            'Admin access required.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1050;

            return Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dashboard',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Here's what's happening with your bookstore today.",
                                    style: TextStyle(color: Color(0xFFB1C5D6)),
                                  ),
                                ],
                              ),
                            ),
                            if (wide) _dateBadge(),
                          ],
                        ),
                        const SizedBox(height: 22),
                        StreamBuilder<List<BookModel>>(
                          stream: _admin.watchBooks(),
                          builder: (context, booksSnap) {
                            return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: _orders.getAllOrders(),
                              builder: (context, ordersSnap) {
                                return StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: _admin.watchCustomers(),
                                  builder: (context, usersSnap) {
                                    return StreamBuilder<
                                      QuerySnapshot<Map<String, dynamic>>
                                    >(
                                      stream: _admin.watchReviews(),
                                      builder: (context, reviewsSnap) {
                                        final hasError =
                                            booksSnap.hasError ||
                                            ordersSnap.hasError ||
                                            usersSnap.hasError ||
                                            reviewsSnap.hasError;

                                        if (hasError) {
                                          return _errorPanel(
                                            'Unable to load dashboard data. '
                                            'Check Firestore rules and connection.',
                                          );
                                        }

                                        final loading =
                                            booksSnap.connectionState ==
                                                ConnectionState.waiting ||
                                            ordersSnap.connectionState ==
                                                ConnectionState.waiting ||
                                            usersSnap.connectionState ==
                                                ConnectionState.waiting ||
                                            reviewsSnap.connectionState ==
                                                ConnectionState.waiting;

                                        if (loading) {
                                          return const Padding(
                                            padding: EdgeInsets.all(40),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: _green,
                                              ),
                                            ),
                                          );
                                        }

                                        final books =
                                            booksSnap.data ?? <BookModel>[];
                                        final orders =
                                            ordersSnap.data?.docs ?? [];
                                        final users =
                                            usersSnap.data?.docs ?? [];
                                        final reviews =
                                            reviewsSnap.data?.docs ?? [];

                                        final sales = orders.fold<double>(0, (
                                          total,
                                          doc,
                                        ) {
                                          final data = doc.data();

                                          if (data['status'] == 'Cancelled') {
                                            return total;
                                          }

                                          return total +
                                              ((data['total'] as num?)
                                                      ?.toDouble() ??
                                                  0);
                                        });

                                        final delivered = orders
                                            .where(
                                              (doc) =>
                                                  doc.data()['status'] ==
                                                  'Delivered',
                                            )
                                            .length;

                                        final stats = [
                                          _Stat(
                                            'Total Books',
                                            '${books.length}',
                                            Icons.menu_book_rounded,
                                            const Color(0xFF20D66B),
                                            '+ live',
                                          ),
                                          _Stat(
                                            'Total Orders',
                                            '${orders.length}',
                                            Icons.shopping_bag_outlined,
                                            const Color(0xFF7852E8),
                                            '$delivered delivered',
                                          ),
                                          _Stat(
                                            'Total Customers',
                                            '${users.length}',
                                            Icons.person_outline,
                                            const Color(0xFF168BFF),
                                            'registered users',
                                          ),
                                          _Stat(
                                            'Total Reviews',
                                            '${reviews.length}',
                                            Icons.star_rounded,
                                            const Color(0xFFFFBE00),
                                            'customer reviews',
                                          ),
                                        ];

                                        return Column(
                                          children: [
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: wide
                                                        ? 4
                                                        : (constraints.maxWidth >
                                                                  600
                                                              ? 2
                                                              : 1),
                                                    mainAxisSpacing: 14,
                                                    crossAxisSpacing: 14,
                                                    mainAxisExtent: 112,
                                                  ),
                                              itemCount: stats.length,
                                              itemBuilder: (_, index) =>
                                                  _statCard(stats[index]),
                                            ),
                                            const SizedBox(height: 18),
                                            if (wide)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    flex: 6,
                                                    child: Column(
                                                      children: [
                                                        _salesCard(
                                                          orders,
                                                          sales,
                                                        ),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        _categoryCard(books),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        _recentOrders(orders),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 18),
                                                  Expanded(
                                                    flex: 4,
                                                    child: Column(
                                                      children: [
                                                        _topBooks(orders),
                                                        const SizedBox(
                                                          height: 16,
                                                        ),
                                                        _recentReviews(
                                                          reviews,
                                                          books,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else ...[
                                              _salesCard(orders, sales),
                                              const SizedBox(height: 16),
                                              _categoryCard(books),
                                              const SizedBox(height: 16),
                                              _topBooks(orders),
                                              const SizedBox(height: 16),
                                              _recentOrders(orders),
                                              const SizedBox(height: 16),
                                              _recentReviews(reviews, books),
                                            ],
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // RESPONSIVE TOP BAR
  Widget _topBar() {
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    final initial = displayName.isEmpty
        ? 'A'
        : displayName.substring(0, 1).toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 420;
        final veryCompact = width < 260;

        return Container(
          height: 68,
          padding: EdgeInsets.symmetric(
            horizontal: veryCompact ? 8 : (compact ? 12 : 22),
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: _green, size: 28),
              if (!veryCompact) ...[
                const SizedBox(width: 7),
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Store',
                          style: TextStyle(
                            color: _green,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (!compact) ...[
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFFD2E1EF),
                  size: 25,
                ),
                const SizedBox(width: 18),
              ],
              CircleAvatar(
                radius: compact ? 17 : 20,
                backgroundColor: const Color(0xFF263C4D),
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                const Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Administrator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF9DB2C4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _dateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFFBBD0E2),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(_today(), style: const TextStyle(color: Color(0xFFD6E4F1))),
        ],
      ),
    );
  }

  String _today() {
    final date = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // RESPONSIVE STAT CARD
  Widget _statCard(_Stat stat) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 220;

        return Container(
          padding: EdgeInsets.all(compact ? 10 : 16),
          decoration: BoxDecoration(
            color: _panel,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 46,
                height: compact ? 34 : 46,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  stat.icon,
                  color: stat.color,
                  size: compact ? 21 : 27,
                ),
              ),
              SizedBox(width: compact ? 8 : 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFBBD0E2),
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 5),
                    Text(
                      stat.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 20 : 24,
                      ),
                    ),
                    Text(
                      stat.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _green,
                        fontSize: compact ? 9 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _panelCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _salesCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
    double totalSales,
  ) {
    final now = DateTime.now();

    final days = List.generate(
      7,
      (index) => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index)),
    );

    final values = List<double>.filled(7, 0);

    for (final order in orders) {
      final data = order.data();

      if (data['status'] == 'Cancelled') continue;

      final rawDate = data['createdAt'];
      final date = rawDate is Timestamp ? rawDate.toDate() : null;

      if (date == null) continue;

      for (var i = 0; i < days.length; i++) {
        if (date.year == days[i].year &&
            date.month == days[i].month &&
            date.day == days[i].day) {
          values[i] += (data['total'] as num?)?.toDouble() ?? 0;
          break;
        }
      }
    }

    final periodSales = values.fold<double>(0, (total, value) => total + value);

    return _panelCard(
      title: 'Sales Overview',
      icon: Icons.bar_chart_rounded,
      action: DropdownButton<String>(
        value: _period,
        dropdownColor: _panel,
        underline: const SizedBox(),
        style: const TextStyle(color: Color(0xFFD6E4F1), fontSize: 12),
        items: const ['Last 7 Days', 'All Time']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) {
          setState(() {
            _period = value ?? 'Last 7 Days';
          });
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rs. ${(_period == 'All Time' ? totalSales : periodSales).toStringAsFixed(0)} sales',
            style: const TextStyle(color: Color(0xFFBBD0E2), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            width: double.infinity,
            child: CustomPaint(
              painter: _SalesPainter(
                values: values,
                color: _green,
                grid: _border,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              return Text(
                '${date.month}/${date.day}',
                style: const TextStyle(color: Color(0xFF9DB2C4), fontSize: 10),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(List<BookModel> books) {
    final counts = <String, int>{};

    for (final book in books) {
      final name = book.category.trim().isEmpty
          ? 'Uncategorized'
          : book.category.trim();

      counts[name] = (counts[name] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final shown = entries.take(6).toList();

    return _panelCard(
      title: 'Books by Category',
      icon: Icons.grid_view_rounded,
      action: const Text(
        'Live data',
        style: TextStyle(color: _green, fontSize: 11),
      ),
      child: shown.isEmpty
          ? _empty('No book categories yet.')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: shown.map((entry) {
                return Container(
                  width: 105,
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2028),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: _green,
                        size: 24,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                          color: Color(0xFFBBD0E2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _topBooks(List<QueryDocumentSnapshot<Map<String, dynamic>>> orders) {
    final counts = <String, int>{};
    final titles = <String, String>{};
    final authors = <String, String>{};
    final images = <String, String>{};

    for (final order in orders) {
      final data = order.data();

      if (data['status'] == 'Cancelled') continue;

      final items = data['items'];
      if (items is! List) continue;

      for (final item in items.whereType<Map>()) {
        final id =
            item['bookId']?.toString() ?? item['title']?.toString() ?? 'book';

        counts[id] =
            (counts[id] ?? 0) + ((item['quantity'] as num?)?.toInt() ?? 0);

        titles[id] = item['title']?.toString() ?? 'Book';
        authors[id] = item['author']?.toString() ?? '';
        images[id] = item['imageUrl']?.toString() ?? '';
      }
    }

    final ids = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    return _panelCard(
      title: 'Top Selling Books',
      icon: Icons.local_fire_department_rounded,
      child: ids.isEmpty
          ? _empty('Sales will appear here after orders are placed.')
          : Column(
              children: ids.take(5).toList().asMap().entries.map((entry) {
                final id = entry.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      _cover(images[id] ?? ''),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[id] ?? 'Book',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              authors[id] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9DB2C4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${counts[id]} sold',
                        style: const TextStyle(
                          color: Color(0xFFD6E4F1),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _recentOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> orders,
  ) {
    final recent = orders.take(5).toList();

    return _panelCard(
      title: 'Recent Orders',
      icon: Icons.shopping_bag_rounded,
      child: recent.isEmpty
          ? _empty('No orders have been placed yet.')
          : Column(
              children: recent.map((doc) {
                final data = doc.data();
                final status = data['status']?.toString() ?? 'Pending';
                final rawDate = data['createdAt'];
                final date = rawDate is Timestamp ? rawDate.toDate() : null;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;

                      return Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${doc.id.substring(0, math.min(8, doc.id.length))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  data['customerName']?.toString() ??
                                      'Customer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF9DB2C4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: compact ? 4 : 10),
                          if (!compact)
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs. ${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 5 : 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  status,
                                ).withValues(alpha: .18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 4 : 8),
                          Text(
                            date == null ? '—' : '${date.day}/${date.month}',
                            style: const TextStyle(
                              color: Color(0xFF9DB2C4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _recentReviews(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> reviews,
    List<BookModel> books,
  ) {
    final bookById = {for (final book in books) book.id: book};

    final sorted = [...reviews]
      ..sort((a, b) {
        final aa = a.data()['createdAt'];
        final bb = b.data()['createdAt'];

        final da = aa is Timestamp ? aa.toDate() : DateTime(2000);
        final db = bb is Timestamp ? bb.toDate() : DateTime(2000);

        return db.compareTo(da);
      });

    return _panelCard(
      title: 'Recent Reviews',
      icon: Icons.star_rounded,
      child: sorted.isEmpty
          ? _empty('Customer reviews will appear here.')
          : Column(
              children: sorted.take(3).map((doc) {
                final data = doc.data();
                final book = bookById[data['bookId']?.toString()];
                final rating = (data['rating'] as num?)?.toInt() ?? 0;
                final safeRating = rating.clamp(0, 5);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cover(book?.imageUrl ?? ''),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book?.title ?? 'Book review',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              data['userName']?.toString() ?? 'Reader',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9DB2C4),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${'★' * safeRating}${'☆' * (5 - safeRating)}  '
                              '${data['comment']?.toString() ?? ''}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFBBD0E2),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _cover(String url) {
    return Container(
      width: 36,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF172A34),
        borderRadius: BorderRadius.circular(5),
      ),
      child: url.trim().isEmpty
          ? const Icon(Icons.menu_book, color: _green, size: 20)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.menu_book, color: _green, size: 20);
              },
            ),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9DB2C4), fontSize: 12),
        ),
      ),
    );
  }

  Widget _errorPanel(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Text(message, style: const TextStyle(color: Colors.orangeAccent)),
    );
  }

  Color _statusColor(String status) {
    return switch (status.toLowerCase()) {
      'pending' => const Color(0xFFFFC107),
      'confirmed' => const Color(0xFFFFB300),
      'processing' => const Color(0xFF168BFF),
      'shipped' => const Color(0xFF8B5CF6),
      'delivered' => const Color(0xFF22D66B),
      'cancelled' => const Color(0xFFFF4D5A),
      _ => Colors.grey,
    };
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color, this.note);

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
}

class _SalesPainter extends CustomPainter {
  _SalesPainter({
    required this.values,
    required this.color,
    required this.grid,
  });

  final List<double> values;
  final Color color;
  final Color grid;

  static const _bgColor = Color(0xFF0B1A21);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    const top = 8.0;
    const bottom = 12.0;
    const right = 8.0;

    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 0.7;

    for (var i = 0; i < 5; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    for (var i = 0; i < values.length; i++) {
      final x =
          chart.left +
          (values.length <= 1 ? 0 : chart.width * i / (values.length - 1));

      canvas.drawLine(Offset(x, chart.top), Offset(x, chart.bottom), gridPaint);
    }

    if (values.isEmpty) return;

    final maxValue = math.max(
      1.0,
      values.fold<double>(0, (a, b) => math.max(a, b)),
    );

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length <= 1
          ? chart.left
          : chart.left + chart.width * i / (values.length - 1);

      points.add(
        Offset(x, chart.bottom - (values[i] / maxValue) * (chart.height * .88)),
      );
    }

    if (points.isEmpty) return;

    final area = Path()
      ..moveTo(points.first.dx, chart.bottom)
      ..lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      area.lineTo(points[i].dx, points[i].dy);
    }

    area
      ..lineTo(points.last.dx, chart.bottom)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: .35), color.withValues(alpha: .02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(chart),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      line.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3.2, Paint()..color = color);
      canvas.drawCircle(point, 1.4, Paint()..color = _bgColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SalesPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.grid != grid;
  }
}
