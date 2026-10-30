import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
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
        title: const Text('Categories'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.black,
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load categories. Check Firestore rules.',
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

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No categories created yet. Add a category to start organizing books.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = data['name']?.toString() ?? 'Unnamed category';

              final description = data['description']?.toString() ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border.all(color: const Color(0xFF1B3039)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sell_outlined, color: _green),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    description.isEmpty ? 'No description' : description,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: PopupMenuButton<String>(
                    iconColor: Colors.white70,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showForm(
                          id: doc.id,
                          name: name,
                          description: description,
                        );
                      }

                      if (value == 'delete') {
                        _delete(doc.id, name);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showForm({
    String? id,
    String name = '',
    String description = '',
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: name);
    final descriptionController = TextEditingController(text: description);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: Text(
          id == null ? 'Add Category' : 'Edit Category',
          style: const TextStyle(color: Colors.white),
        ),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: Text(id == null ? 'Create' : 'Save changes'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        if (id == null) {
          await _service.addCategory(
            name: nameController.text,
            description: descriptionController.text,
          );
        } else {
          await _service.updateCategory(
            id: id,
            name: nameController.text,
            description: descriptionController.text,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                id == null ? 'Category created.' : 'Category updated.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Bad state: ', '')),
            ),
          );
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _delete(String id, String name) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text(
          'Delete category?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "$name"? Existing books will not be deleted, '
          'but their category text will remain unchanged.',
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
      await _service.deleteCategory(id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category deleted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete category: $e')),
        );
      }
    }
  }
}
