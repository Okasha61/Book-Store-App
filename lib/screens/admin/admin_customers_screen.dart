import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

class AdminCustomersScreen extends StatelessWidget {
  AdminCustomersScreen({super.key});

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
        title: const Text('Customers'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchCustomers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load customers. Check Firestore rules.',
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
            ..sort(
              (a, b) =>
                  (a.data()['name']?.toString() ?? '').toLowerCase().compareTo(
                    (b.data()['name']?.toString() ?? '').toLowerCase(),
                  ),
            );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${docs.length} registered customers',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(
                        child: Text(
                          'No customer profiles found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final rawName = data['name']?.toString().trim();
                          final name = rawName != null && rawName.isNotEmpty
                              ? rawName
                              : 'Customer';

                          final email = data['email']?.toString() ?? '';
                          final phone =
                              data['phone']?.toString() ?? 'No phone number';
                          final provider =
                              data['provider']?.toString() ?? 'Not specified';

                          return Container(
                            decoration: BoxDecoration(
                              color: _panel,
                              border: Border.all(
                                color: const Color(0xFF1B3039),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _green.withValues(alpha: .16),
                                foregroundColor: _green,
                                child: Text(name.substring(0, 1).toUpperCase()),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '$email\n$phone\nUID: ${doc.id}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  height: 1.5,
                                  fontSize: 12,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'View customer details',
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: _green,
                                ),
                                onPressed: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: _panel,
                                      title: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      content: Text(
                                        'Email: $email\n'
                                        'Phone: $phone\n'
                                        'Customer ID: ${doc.id}\n'
                                        'Provider: $provider',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
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
}
