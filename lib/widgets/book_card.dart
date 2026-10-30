import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/book_model.dart';
import '../screens/books/book_details_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../services/cart_service.dart';
import '../services/review_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/login_prompt.dart';
import 'wishlist_button.dart';

class BookCard extends StatefulWidget {
  const BookCard({
    super.key,
    required this.book,
    this.rating,
    this.width = 160,
  });

  final BookModel book;
  final RatingSummary? rating;
  final double width;

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding) return;

    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(
        context,
        action: 'add books to your cart',
      );
      if (!loggedIn || !mounted) return;
    }

    setState(() => _adding = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await CartService().addToCart(widget.book);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${widget.book.title} added to your cart.'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () async {
                if (FirebaseAuth.instance.currentUser == null) {
                  final loggedIn = await requireLogin(
                    context,
                    action: 'view your cart',
                  );
                  if (!loggedIn || !mounted) return;
                }
                navigator.push(
                  MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                );
              },
            ),
          ),
        );
    } catch (error) {
      final message = error is StateError
          ? error.message.toString()
          : 'Could not add this book to your cart. Please try again.';

      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookDetailsScreen(book: widget.book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final inStock = book.stock > 0;
    final rating = widget.rating;

    return SizedBox(
      width: widget.width,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: AppColors.coverBg,
                        padding: const EdgeInsets.all(12),
                        child: BookCover(imageUrl: book.imageUrl, radius: 6),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: WishlistButton(bookId: book.id, size: 32),
                    ),
                    if (!inStock)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38,
                        child: Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ratingRow(rating),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatPrice(book.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _cartButton(inStock),
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

  Widget _ratingRow(RatingSummary? rating) {
    if (rating == null || rating.count == 0) {
      return const Text(
        'No ratings yet',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      );
    }

    return Row(
      children: [
        const Icon(Icons.star_rounded, color: AppColors.star, size: 15),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '${formatRating(rating.average)} (${formatCount(rating.count)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cartButton(bool inStock) {
    return Tooltip(
      message: inStock ? 'Add to cart' : 'Out of stock',
      child: Material(
        color: inStock ? AppColors.green : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: inStock && !_adding ? _addToCart : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: _adding
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Book cover with loading and error placeholders.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.radius = 0,
  });

  final String imageUrl;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl.trim().isEmpty
          ? _placeholder()
          : Image.network(
              imageUrl,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(Icons.menu_book_rounded, size: 46, color: AppColors.green),
    );
  }
}
