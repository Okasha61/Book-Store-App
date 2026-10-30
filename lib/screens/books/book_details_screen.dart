import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/book_model.dart';
import '../../services/cart_service.dart';
import '../../services/review_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/login_prompt.dart';
import '../../widgets/book_card.dart';
import '../../widgets/wishlist_button.dart';
import '../cart/cart_screen.dart';
import 'book_reviews_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.book});

  final BookModel book;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late final Stream<List<BookReview>> _reviews = ReviewService().watchReviews(
    widget.book.id,
  );

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

  void _openReviews() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookReviewsScreen(book: widget.book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final inStock = book.stock > 0;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Book Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: WishlistButton(bookId: book.id, size: 38)),
          ),
        ],
      ),
      body: StreamBuilder<List<BookReview>>(
        stream: _reviews,
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? const <BookReview>[];
          final average = reviews.isEmpty
              ? 0.0
              : reviews.fold<int>(0, (sum, r) => sum + r.rating) /
                    reviews.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                height: 300,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.coverBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: BookCover(imageUrl: book.imageUrl, radius: 8),
              ),
              const SizedBox(height: 20),
              Text(
                book.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'By ${book.author}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _openReviews,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.star,
                        size: 22,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        reviews.isEmpty
                            ? 'No ratings yet'
                            : '${formatRating(average)}  (${formatCount(reviews.length)} ${reviews.length == 1 ? 'review' : 'reviews'})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    book.category,
                    fg: AppColors.green,
                    bg: const Color(0xFFE3F8E6),
                  ),
                  _pill(
                    inStock ? '${book.stock} in stock' : 'Out of stock',
                    fg: inStock ? AppColors.textPrimary : Colors.red.shade700,
                    bg: inStock ? AppColors.coverBg : const Color(0xFFFDE4E6),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'About this book',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.description.trim().isEmpty
                    ? 'No description available.'
                    : book.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openReviews,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text(
                    'Ratings & Reviews',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatPrice(book.price),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: inStock && !_adding ? _addToCart : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _adding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      inStock ? 'Add to Cart' : 'Out of Stock',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
