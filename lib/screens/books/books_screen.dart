import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../services/book_service.dart';
import '../../services/cart_service.dart';
import '../../services/category_service.dart';
import '../../services/wishlist_service.dart';
import '../../utils/constants.dart';
import '../../utils/login_prompt.dart';
import '../cart/cart_screen.dart';
import 'book_reviews_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key, this.initialCategory, this.initialQuery});

  final String? initialCategory;
  final String? initialQuery;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final BookService _bookService = BookService();
  final CategoryService _categoryService = CategoryService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialCategory ?? 'All';
    _searchQuery = widget.initialQuery ?? '';
    _searchController.text = _searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BookModel> _filterBooks(List<BookModel> books) {
    final query = _searchQuery.trim().toLowerCase();

    return books.where((book) {
      final matchesSearch =
          query.isEmpty ||
          book.title.toLowerCase().contains(query) ||
          book.author.toLowerCase().contains(query) ||
          book.category.toLowerCase().contains(query);

      final matchesCategory =
          _selectedCategory == 'All' ||
          book.category.trim().toLowerCase() ==
              _selectedCategory.trim().toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _addToCart(BookModel book) async {
    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(
        context,
        action: 'add books to your cart',
      );

      if (!mounted || !loggedIn || FirebaseAuth.instance.currentUser == null) {
        return;
      }
    }

    try {
      await _cartService.addToCart(book);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${book.title} added to your cart.'),
            action: SnackBarAction(label: 'VIEW CART', onPressed: _openCart),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      final message = error is StateError
          ? error.message.toString()
          : 'Could not add this book to your cart. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openCart() async {
    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(context, action: 'view your cart');

      if (!mounted || !loggedIn || FirebaseAuth.instance.currentUser == null) {
        return;
      }
    }

    if (!mounted) return;

    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen()));
  }

  void _openReviews(BookModel book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookReviewsScreen(book: book)),
    );
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse Books',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Find your next favourite read',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Cart',
            onPressed: _openCart,
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bottomls.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const ColoredBox(color: AppColors.pageBg),
          ),
          const ColoredBox(color: Color(0x6600100E)),
          SafeArea(
            child: StreamBuilder<List<BookModel>>(
              stream: _bookService.getBooks(),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.hasError) {
                  return _buildMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unable to load books',
                    message:
                        'Please check your internet connection and '
                        'Firestore security rules.',
                    buttonText: 'Try Again',
                    onPressed: () => setState(() {}),
                  );
                }

                if (bookSnapshot.connectionState == ConnectionState.waiting &&
                    !bookSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  );
                }

                final allBooks = bookSnapshot.data ?? <BookModel>[];

                return StreamBuilder<List<CategoryModel>>(
                  stream: _categoryService.watchCategories(),
                  builder: (context, categorySnapshot) {
                    // Use admin-managed categories when available.
                    // If the category stream is empty or fails, derive
                    // categories from the existing books.
                    final savedCategories =
                        categorySnapshot.data ?? <CategoryModel>[];

                    final resolvedCategories = CategoryService.resolve(
                      savedCategories,
                      allBooks,
                    );

                    final categoryNames = <String>[
                      'All',
                      ...resolvedCategories
                          .map((category) => category.name.trim())
                          .where((name) => name.isNotEmpty)
                          .where((name) => name.toLowerCase() != 'all'),
                    ];

                    // Remove duplicate names without changing their order.
                    final uniqueCategoryNames = <String>[];
                    final seenNames = <String>{};

                    for (final name in categoryNames) {
                      if (seenNames.add(name.toLowerCase())) {
                        uniqueCategoryNames.add(name);
                      }
                    }

                    // Keep an initial category if it is still available.
                    final selectedCategoryExists = uniqueCategoryNames.any(
                      (category) =>
                          category.toLowerCase() ==
                          _selectedCategory.toLowerCase(),
                    );

                    final activeCategory = selectedCategoryExists
                        ? _selectedCategory
                        : 'All';

                    final filteredBooks = _filterBooks(allBooks);

                    // Filtering uses the active category, including the
                    // initial category passed from another screen.
                    final displayedBooks = activeCategory == _selectedCategory
                        ? filteredBooks
                        : allBooks.where((book) {
                            final query = _searchQuery.trim().toLowerCase();

                            final matchesSearch =
                                query.isEmpty ||
                                book.title.toLowerCase().contains(query) ||
                                book.author.toLowerCase().contains(query) ||
                                book.category.toLowerCase().contains(query);

                            return matchesSearch;
                          }).toList();

                    // Keep the selected filter valid if a category was
                    // removed from Firestore.
                    if (_selectedCategory != activeCategory) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedCategory != activeCategory) {
                          setState(() {
                            _selectedCategory = activeCategory;
                          });
                        }
                      });
                    }

                    final booksToShow = activeCategory == 'All'
                        ? displayedBooks
                        : displayedBooks
                              .where(
                                (book) =>
                                    book.category.trim().toLowerCase() ==
                                    activeCategory.trim().toLowerCase(),
                              )
                              .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          child: _buildSearchField(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Explore Books',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.coverBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${booksToShow.length} books',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: uniqueCategoryNames.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 9),
                            itemBuilder: (context, index) {
                              final category = uniqueCategoryNames[index];
                              final isSelected =
                                  activeCategory.toLowerCase() ==
                                  category.toLowerCase();

                              return ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                showCheckmark: false,
                                selectedColor: AppColors.green,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.green
                                      : AppColors.border,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: booksToShow.isEmpty
                              ? _buildMessage(
                                  icon: Icons.menu_book_outlined,
                                  title: allBooks.isEmpty
                                      ? 'No books available yet'
                                      : 'No books found',
                                  message: allBooks.isEmpty
                                      ? 'Books will appear here when they '
                                            'are added to your database.'
                                      : 'Try another search or select '
                                            'a different category.',
                                  buttonText: allBooks.isEmpty
                                      ? null
                                      : 'Clear Filters',
                                  onPressed: allBooks.isEmpty
                                      ? null
                                      : _clearFilters,
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;

                                    final crossAxisCount = width >= 1000
                                        ? 5
                                        : width >= 750
                                        ? 4
                                        : width >= 480
                                        ? 3
                                        : 2;

                                    return GridView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        24,
                                      ),
                                      itemCount: booksToShow.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            crossAxisSpacing: 14,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 0.57,
                                          ),
                                      itemBuilder: (context, index) {
                                        final book = booksToShow[index];

                                        return _BookCard(
                                          book: book,
                                          onTap: () => _showBookDetails(book),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search books, authors...',
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.lime),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              )
            : null,
        filled: true,
        fillColor: AppColors.searchFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.coverBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 42, color: AppColors.green),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
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
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBookDetails(BookModel book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.pageBg,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Book Details',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _WishlistButton(bookId: book.id),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    height: 220,
                    child: _BookCover(
                      imageUrl: book.imageUrl,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'By ${book.author}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _detailChip(
                      icon: Icons.category_outlined,
                      label: book.category,
                    ),
                    _detailChip(
                      icon: Icons.inventory_2_outlined,
                      label: book.stock > 0
                          ? '${book.stock} in stock'
                          : 'Out of stock',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Rs. ${book.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'About this book',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  book.description.isEmpty
                      ? 'No description available.'
                      : book.description,
                  style: const TextStyle(
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 49,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openReviews(book);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline_rounded),
                    label: const Text(
                      'Ratings & Reviews',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: book.stock <= 0
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            _addToCart(book);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      book.stock <= 0 ? 'Out of Stock' : 'Add to Cart',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.coverBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final BookModel book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.coverBg,
                        padding: const EdgeInsets.all(8),
                        child: _BookCover(
                          imageUrl: book.imageUrl,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: _WishlistButton(bookId: book.id),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Rs. ${book.price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            book.stock > 0
                                ? Icons.check_circle_outline_rounded
                                : Icons.cancel_outlined,
                            size: 13,
                            color: book.stock > 0
                                ? AppColors.green
                                : AppColors.heart,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              book.stock > 0 ? 'In stock' : 'Out of stock',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: book.stock > 0
                                    ? AppColors.green
                                    : AppColors.heart,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatefulWidget {
  const _WishlistButton({required this.bookId});

  final String bookId;

  @override
  State<_WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<_WishlistButton> {
  final WishlistService _wishlistService = WishlistService();

  bool _isWishlisted = false;
  bool _loading = true;
  bool _busy = false;

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _loadStatus();

    _authSubscription = FirebaseAuth.instance.authStateChanges().skip(1).listen(
      (user) {
        if (user == null) {
          if (mounted) {
            setState(() {
              _isWishlisted = false;
              _loading = false;
            });
          }
        } else {
          _loadStatus();
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    try {
      final result = await _wishlistService.isWishlisted(widget.bookId);

      if (!mounted) return;

      setState(() {
        _isWishlisted = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggle() async {
    if (_busy || _loading) return;

    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(
        context,
        action: 'save books to your wishlist',
      );

      if (!mounted || !loggedIn || FirebaseAuth.instance.currentUser == null) {
        return;
      }

      await _loadStatus();

      if (!mounted) return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _wishlistService.toggleWishlist(widget.bookId);

      if (!mounted) return;

      setState(() {
        _isWishlisted = !_isWishlisted;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              _isWishlisted
                  ? 'Added to your wishlist.'
                  : 'Removed from your wishlist.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      final message = error is StateError
          ? error.message.toString()
          : 'Could not update your wishlist. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
      visualDensity: VisualDensity.compact,
      onPressed: _loading || _busy ? null : _toggle,
      icon: _loading || _busy
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            )
          : Icon(
              _isWishlisted
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isWishlisted ? AppColors.green : AppColors.textSecondary,
              size: 22,
            ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.imageUrl, required this.borderRadius});

  final String imageUrl;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: imageUrl.trim().isEmpty
          ? _placeholder()
          : Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return Container(
                  color: AppColors.coverBg,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.green,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _placeholder();
              },
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      color: AppColors.coverBg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        size: 52,
        color: AppColors.green,
      ),
    );
  }
}
