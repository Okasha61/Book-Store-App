import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../widgets/admin_drawer.dart';
import '../main/main_screen.dart';
import 'admin_books_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_settings_screen.dart';

/// Responsive admin navigation shell. Each section keeps its existing screen/UI.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _bg = Color(0xFF061116);

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 6);
  }

  final List<Widget> _pages = [
    const AdminDashboardScreen(),
    const AdminBooksScreen(),
    const AdminCategoriesScreen(),
    const AdminOrdersScreen(),
    AdminCustomersScreen(),
    AdminReviewsScreen(),
    const AdminSettingsScreen(),
  ];

  void _backToApp() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AdminService().isAdmin) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;

        if (wide) {
          return Scaffold(
            backgroundColor: _bg,
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: AdminDrawer(
                    selectedIndex: _index,
                    onSelect: (value) => setState(() => _index = value),
                    onBackToApp: _backToApp,
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFF1B3039)),
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          drawer: AdminDrawer(
            selectedIndex: _index,
            onSelect: (value) => setState(() => _index = value),
            onBackToApp: _backToApp,
          ),
          appBar: AppBar(
            backgroundColor: _bg,
            foregroundColor: Colors.white,
            title: const Text('Book Store Admin'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
          body: IndexedStack(index: _index, children: _pages),
        );
      },
    );
  }
}
