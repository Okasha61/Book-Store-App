import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/wishlist_service.dart';
import '../utils/constants.dart';
import '../utils/login_prompt.dart';

/// Heart button that follows the live wishlist state in Firestore.
class WishlistButton extends StatefulWidget {
  const WishlistButton({super.key, required this.bookId, this.size = 34});

  final String bookId;
  final double size;

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  final WishlistService _service = WishlistService();
  late final Stream<bool> _stream;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _stream = _service.watchWishlistBookIds().map(
      (ids) => ids.contains(widget.bookId),
    );
  }

  Future<void> _toggle(bool current) async {
    if (_busy) return;

    if (FirebaseAuth.instance.currentUser == null) {
      final loggedIn = await requireLogin(
        context,
        action: 'save books to your wishlist',
      );
      if (!loggedIn || !mounted) return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _service.toggleWishlist(widget.bookId);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              current
                  ? 'Removed from your wishlist.'
                  : 'Added to your wishlist.',
            ),
          ),
        );
    } catch (error) {
      final message = error is StateError
          ? error.message.toString()
          : 'Could not update your wishlist. Please try again.';

      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _stream,
      initialData: false,
      builder: (context, snapshot) {
        final wished = snapshot.data ?? false;

        return Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1.5,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _busy ? null : () => _toggle(wished),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Icon(
                wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: widget.size * 0.55,
                color: wished ? AppColors.green : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
