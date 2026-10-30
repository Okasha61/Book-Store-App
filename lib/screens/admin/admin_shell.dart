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

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const Color _bg = Color(0xFF061116);

  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 6);
  }

  Widget _buildPage() {
    switch (_index) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return const AdminBooksScreen();
      case 2:
        return const AdminCategoriesScreen();
      case 3:
        return const AdminOrdersScreen();
      case 4:
        return AdminCustomersScreen();
      case 5:
        return AdminReviewsScreen();
      case 6:
        return const AdminSettingsScreen();
      default:
        return const AdminDashboardScreen();
    }
  }

  void _selectPage(int value) {
    if (value < 0 || value > 6) return;

    setState(() {
      _index = value;
    });
  }

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
        final bool wide = constraints.maxWidth >= 1000;

        final page = KeyedSubtree(
          key: ValueKey<int>(_index),
          child: _buildPage(),
        );

        if (wide) {
          return Scaffold(
            backgroundColor: _bg,
            body: Row(
              children: [
                SizedBox(
                  width: 250,
                  child: AdminDrawer(
                    selectedIndex: _index,
                    onSelect: _selectPage,
                    onBackToApp: _backToApp,
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFF1B3039)),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          drawer: AdminDrawer(
            selectedIndex: _index,
            onSelect: _selectPage,
            onBackToApp: _backToApp,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 52,
                  color: _bg,
                  alignment: Alignment.centerLeft,
                  child: Builder(
                    builder: (drawerContext) {
                      return IconButton(
                        tooltip: 'Open admin menu',
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(drawerContext).openDrawer();
                        },
                      );
                    },
                  ),
                ),
                Expanded(child: page),
              ],
            ),
          ),
        );
      },
    );
  }
}
