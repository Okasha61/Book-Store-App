import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/wishlist_service.dart';
import '../../utils/constants.dart';
import '../../utils/login_prompt.dart';
import '../books/book_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistService _wishlistService = WishlistService();
  final BookService _bookService = BookService();

  Future<void> _removeFromWishlist(String bookId) async {
    try {
      await _wishlistService.removeFromWishlist(bookId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book removed from wishlist.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove this book. Please try again.'),
        ),
      );
    }
  }

  Future<void> _handleGuest() async {
    await requireLogin(context, action: 'view your wishlist');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Wishlist',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Your favourite books in one place',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bottomls.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: AppColors.pageBg);
            },
          ),
          const ColoredBox(color: Color(0x6600100E)),
          SafeArea(
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                final user =
                    authSnapshot.data ??
                    (authSnapshot.connectionState == ConnectionState.waiting
                        ? FirebaseAuth.instance.currentUser
                        : null);

                if (authSnapshot.connectionState == ConnectionState.waiting &&
                    user == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  );
                }

                if (user == null) {
                  return _buildGuestView();
                }

                return StreamBuilder<List<String>>(
                  key: ValueKey(user.uid),
                  stream: _wishlistService.watchWishlistBookIds(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildMessage(
                        icon: Icons.cloud_off_outlined,
                        title: 'Unable to load wishlist',
                        message: 'Please check your connection and try again.',
                        buttonText: 'Retry',
                        onPressed: () {
                          setState(() {});
                        },
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                        ),
                      );
                    }

                    final bookIds = snapshot.data ?? <String>[];

                    if (bookIds.isEmpty) {
                      return _buildMessage(
                        icon: Icons.favorite_border_rounded,
                        title: 'Your wishlist is empty',
                        message:
                            'Save books you love and find them here later.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookIds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bookId = bookIds[index];

                        return FutureBuilder<BookModel?>(
                          future: _bookService.getBookById(bookId),
                          builder: (context, bookSnapshot) {
                            if (bookSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 110,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.green,
                                  ),
                                ),
                              );
                            }

                            if (bookSnapshot.hasError) {
                              return const SizedBox(
                                height: 80,
                                child: Center(
                                  child: Text(
                                    'Could not load this book.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }

                            final book = bookSnapshot.data;

                            if (book == null) {
                              return const SizedBox.shrink();
                            }

                            return _WishlistBookCard(
                              book: book,
                              onRemove: () {
                                _removeFromWishlist(book.id);
                              },
                            );
                          },
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
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.headerDark.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 38,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your personal wishlist',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to save your favourite books and '
                'access them whenever you want.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.headerDark.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.green, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (buttonText != null && onPressed != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(onPressed: onPressed, child: Text(buttonText)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WishlistBookCard extends StatelessWidget {
  const _WishlistBookCard({required this.book, required this.onRemove});

  final BookModel book;
  final VoidCallback onRemove;

  void _openBookDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailsScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openBookDetails(context),
        child: Container(
          height: 142,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.headerDark.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 82,
                  height: double.infinity,
                  color: AppColors.coverBg,
                  padding: const EdgeInsets.all(4),
                  child: book.imageUrl.trim().isEmpty
                      ? const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.green,
                          size: 36,
                        )
                      : Image.network(
                          book.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.green,
                              size: 36,
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${book.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      book.stock > 0 ? 'In stock' : 'Out of stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from wishlist',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.heart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
