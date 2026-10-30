import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

class AdminReviewsScreen extends StatelessWidget {
  AdminReviewsScreen({super.key});

  static const _bg = Color(0xFF061116);
  static const _panel = Color(0xFF0B1A21);
  static const _green = Color(0xFF22D66B);

  final AdminService _service = AdminService();

  @override
  Widget build(BuildContext context) {
    if (!_service.isAdmin) {
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

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Reviews'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchReviews(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load reviews. Check Firestore rules.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _green),
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final av = a.data()['createdAt'];
              final bv = b.data()['createdAt'];

              final ad = av is Timestamp ? av.toDate() : DateTime(2000);

              final bd = bv is Timestamp ? bv.toDate() : DateTime(2000);

              return bd.compareTo(ad);
            });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${docs.length} reviews',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'No reviews submitted yet.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final rating =
                              (((data['rating'] as num?)?.toInt() ?? 0).clamp(
                                0,
                                5,
                              )).toInt();

                          final comment = data['comment']?.toString() ?? '';

                          final user = data['userName']?.toString() ?? 'Reader';

                          final date = data['createdAt'];

                          final dateText = date is Timestamp
                              ? '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}'
                              : 'Date unavailable';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _panel,
                              border: Border.all(
                                color: const Color(0xFF1B3039),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      color: _green,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Book ID: ${data['bookId'] ?? 'Unknown'}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${'★' * rating}${'☆' * (5 - rating)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFC107),
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  comment.isEmpty
                                      ? 'No written comment.'
                                      : comment,
                                  style: const TextStyle(
                                    color: Color(0xFFBBD0E2),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Review document: ${doc.id}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _confirmDelete(context, doc.id, user),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    label: const Text(
                                      'Delete review',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String user,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text(
          'Delete review?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove the review submitted by $user? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('book_reviews')
          .doc(id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete review: $e')));
      }
    }
  }
}
