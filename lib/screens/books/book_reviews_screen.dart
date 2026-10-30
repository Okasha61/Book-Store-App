import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/book_model.dart';
import '../../services/review_service.dart';

class BookReviewsScreen extends StatefulWidget {
  const BookReviewsScreen({super.key, required this.book});

  final BookModel book;

  @override
  State<BookReviewsScreen> createState() => _BookReviewsScreenState();
}

class _BookReviewsScreenState extends State<BookReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  int _rating = 5;
  bool _checkingEligibility = true;
  bool _canReview = false;
  bool _loadingMyReview = false;
  bool _submitting = false;
  BookReview? _myReview;

  @override
  void initState() {
    super.initState();
    _checkReviewEligibility();
    _loadMyReview();
    _auth.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _canReview = false;
          _checkingEligibility = false;
          _myReview = null;
          _commentController.clear();
          _rating = 5;
        });
      } else {
        _checkReviewEligibility();
        _loadMyReview();
      }
    });
  }

  Future<void> _checkReviewEligibility() async {
    if (_auth.currentUser == null) {
      if (!mounted) return;
      setState(() {
        _canReview = false;
        _checkingEligibility = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _checkingEligibility = true);
    }

    try {
      final eligible = await _reviewService.canReviewBook(widget.book.id);

      if (!mounted) return;

      setState(() {
        _canReview = eligible;
        _checkingEligibility = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _canReview = false;
        _checkingEligibility = false;
      });
    }
  }

  Future<void> _loadMyReview() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _myReview = null;
        _loadingMyReview = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loadingMyReview = true);
    }

    try {
      final review = await _reviewService.getMyReview(widget.book.id);

      if (!mounted) return;

      setState(() {
        _myReview = review;

        if (review != null) {
          _rating = review.rating;
          _commentController.text = review.comment;
        } else {
          _rating = 5;
          _commentController.clear();
        }

        _loadingMyReview = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMyReview = false);
    }
  }

  Future<void> _submitReview() async {
    if (_auth.currentUser == null) {
      _showMessage('Please log in to submit a review.');
      return;
    }

    if (!_canReview) {
      _showMessage('You can review this book after it is delivered.');
      return;
    }

    if (_rating < 1 || _rating > 5) {
      _showMessage('Please select a rating.');
      return;
    }

    if (_commentController.text.trim().length > 1000) {
      _showMessage('Your review cannot exceed 1000 characters.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await _reviewService.submitReview(
        bookId: widget.book.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      await _loadMyReview();

      if (!mounted) return;

      _showMessage(
        _myReview == null
            ? 'Review submitted successfully.'
            : 'Review saved successfully.',
      );
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to submit your review. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _reviewService.deleteMyReview(widget.book.id);

      if (!mounted) return;

      setState(() {
        _myReview = null;
        _rating = 5;
        _commentController.clear();
      });

      _showMessage('Review deleted successfully.');
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to delete your review. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF00100E);
    const surface = Color(0xFF0C1B21);
    const accent = Color(0xFF65E572);
    const muted = Color(0xFF9EAFB4);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Book Reviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<BookReview>>(
          stream: _reviewService.watchReviews(widget.book.id),
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? <BookReview>[];

            final average = reviews.isEmpty
                ? 0.0
                : reviews.fold<int>(0, (sum, review) => sum + review.rating) /
                      reviews.length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 82,
                          height: 112,
                          child: widget.book.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.book.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.menu_book_rounded,
                                    color: accent,
                                    size: 36,
                                  ),
                                )
                              : const Icon(
                                  Icons.menu_book_rounded,
                                  color: accent,
                                  size: 36,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.book.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.book.author,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: accent,
                                  size: 22,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  average.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
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
                const SizedBox(height: 22),
                const Text(
                  'Write a Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildReviewForm(
                  surface: surface,
                  accent: accent,
                  muted: muted,
                ),
                const SizedBox(height: 26),
                const Text(
                  'Customer Reviews',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: accent),
                    ),
                  )
                else if (snapshot.hasError)
                  const Text(
                    'Unable to load reviews. Please try again later.',
                    style: TextStyle(color: muted),
                  )
                else if (reviews.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'No reviews yet. Be the first to review this book after delivery.',
                      style: TextStyle(color: muted),
                    ),
                  )
                else
                  ...reviews.map(
                    (review) => _buildReviewCard(
                      review,
                      surface: surface,
                      accent: accent,
                      muted: muted,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReviewForm({
    required Color surface,
    required Color accent,
    required Color muted,
  }) {
    if (_checkingEligibility || _loadingMyReview) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF65E572)),
        ),
      );
    }

    if (_auth.currentUser == null) {
      return _messageCard(
        surface: surface,
        icon: Icons.lock_outline_rounded,
        title: 'Login Required',
        message: 'Please log in to write a review.',
        muted: muted,
      );
    }

    if (!_canReview) {
      return _messageCard(
        surface: surface,
        icon: Icons.local_shipping_outlined,
        title: 'Review After Delivery',
        message:
            'You can rate and review this book after your order status becomes Delivered.',
        muted: muted,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _myReview == null ? 'Rate this book' : 'Update your rating',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final star = index + 1;

              return IconButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _rating = star),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 42),
                icon: Icon(
                  star <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: accent,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 4,
            maxLength: 1000,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this book (optional)',
              hintStyle: TextStyle(color: muted.withValues(alpha: 0.8)),
              filled: true,
              fillColor: const Color(0xFF071512),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: TextStyle(color: muted),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF00100E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00100E),
                      ),
                    )
                  : Text(
                      _myReview == null ? 'Submit Review' : 'Update Review',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          if (_myReview != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _submitting ? null : _deleteReview,
                child: const Text(
                  'Delete My Review',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _messageCard({
    required Color surface,
    required IconData icon,
    required String title,
    required String message,
    required Color muted,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF65E572), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(message, style: TextStyle(color: muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BookReview review, {
    required Color surface,
    required Color accent,
    required Color muted,
  }) {
    final dateText = review.createdAt == null
        ? ''
        : '${review.createdAt!.day.toString().padLeft(2, '0')}/'
              '${review.createdAt!.month.toString().padLeft(2, '0')}/'
              '${review.createdAt!.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'C',
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: accent,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment, style: TextStyle(color: muted, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
