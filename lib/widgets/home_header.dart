import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/cart/cart_screen.dart';
import '../services/cart_service.dart';
import '../utils/constants.dart';
import '../utils/login_prompt.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _search = TextEditingController();
  late final Stream<int> _cartCount;

  @override
  void initState() {
    super.initState();

    _cartCount = CartService().getCartItems().map(
      (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final query = value.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    widget.onSearch(query);
    _search.clear();
  }

  Future<void> _openCart() async {
    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(context, action: 'view your cart');
      if (!loggedIn || !mounted) return;
    }

    if (!mounted) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        color: AppColors.headerDark,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/icon.jpg',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.lime,
                            size: 44,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BookStore',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Read More  •  Grow More',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _cartIcon(),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submit,
                  cursorColor: AppColors.lime,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search for books, authors, categories...',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB4BFBC),
                      fontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                    ),
                    filled: true,
                    fillColor: AppColors.searchFill,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.lime,
                        width: 1.2,
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

  Widget _cartIcon() {
    return StreamBuilder<int>(
      stream: _cartCount,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          tooltip: 'My Cart',
          onPressed: _openCart,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 30,
              ),
              if (count > 0)
                Positioned(
                  top: -8,
                  right: -9,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
