import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onBackToApp,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onBackToApp;

  static const _green = Color(0xFF22D66B);

  static const _items = <(IconData, String)>[
    (Icons.dashboard_outlined, 'Dashboard'),
    (Icons.menu_book_outlined, 'Books'),
    (Icons.category_outlined, 'Categories'),
    (Icons.shopping_bag_outlined, 'Orders'),
    (Icons.people_outline, 'Customers'),
    (Icons.star_outline, 'Reviews'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF061116),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/icon.jpg',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.menu_book_rounded,
                          color: _green,
                          size: 34,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOOKNEST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'ADMIN PANEL',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF1B3039)),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Sidebar bottom background image.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 300,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/admin.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox.shrink();
                          },
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF061116),
                                Color(0xCC061116),
                                Color(0x33061116),
                              ],
                              stops: [0.0, 0.38, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sidebar navigation.
                  ListView(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    children: [
                      for (var index = 0; index < _items.length; index++)
                        Builder(
                          builder: (context) {
                            final item = _items[index];
                            final selected = selectedIndex == index;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  item.$1,
                                  color: selected ? _green : Colors.white60,
                                ),
                                title: Text(
                                  item.$2,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: selected,
                                selectedTileColor: _green.withValues(
                                  alpha: .12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onSelect(index);
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.arrow_back_rounded,
                            color: _green,
                          ),
                          title: const Text(
                            'Back to App',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: onBackToApp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
