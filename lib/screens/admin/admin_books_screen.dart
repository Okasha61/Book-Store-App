import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/book_model.dart';
import '../../models/category_model.dart';
import '../../services/book_service.dart';
import '../../services/category_service.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  static const String _adminUid = 'fOztvfecJdccyg6wref0AnE2FJg1';

  final BookService _bookService = BookService();

  bool get _isAdmin => FirebaseAuth.instance.currentUser?.uid == _adminUid;

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Books')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Access denied. Only the authorized admin can open this screen.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Books')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
      body: StreamBuilder<List<BookModel>>(
        stream: _bookService.getBooks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load books.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data ?? [];

          if (books.isEmpty) {
            return const Center(
              child: Text('No books found. Tap Add Book to create one.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final book = books[index];

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: SizedBox(
                    width: 56,
                    height: 72,
                    child: book.imageUrl.trim().isEmpty
                        ? const Icon(Icons.menu_book, size: 36)
                        : Image.network(
                            book.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.menu_book, size: 36),
                          ),
                  ),
                  title: Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${book.author}\n'
                      'Category: ${book.category}\n'
                      'Price: ${book.price.toStringAsFixed(2)} | '
                      'Stock: ${book.stock}'
                      '${book.isFeatured ? '\nFeatured book' : ''}',
                    ),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showBookForm(book: book);
                      } else if (value == 'delete') {
                        _confirmDelete(book);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
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

  Future<void> _showBookForm({BookModel? book}) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final descriptionController = TextEditingController(
      text: book?.description ?? '',
    );
    final priceController = TextEditingController(
      text: book == null ? '' : book.price.toString(),
    );
    final stockController = TextEditingController(
      text: book == null ? '0' : book.stock.toString(),
    );

    String? selectedCategory = book?.category;
    bool isFeatured = book?.isFeatured ?? false;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    final categoriesStream = CategoryService().watchCategories();

    try {
      final result = await showDialog<_BookFormResult>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(book == null ? 'Add Book' : 'Edit Book'),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _textField(titleController, 'Book title'),
                          _textField(authorController, 'Author'),
                          _textField(
                            descriptionController,
                            'Description',
                            maxLines: 3,
                          ),

                          // Dynamic categories from Admin Categories.
                          StreamBuilder<List<CategoryModel>>(
                            stream: categoriesStream,
                            builder: (context, snapshot) {
                              final names =
                                  (snapshot.data ?? [])
                                      .map((category) => category.name.trim())
                                      .where((name) => name.isNotEmpty)
                                      .toSet()
                                      .toList()
                                    ..sort(
                                      (a, b) => a.toLowerCase().compareTo(
                                        b.toLowerCase(),
                                      ),
                                    );

                              final oldCategory = selectedCategory?.trim();

                              if (oldCategory != null &&
                                  oldCategory.isNotEmpty &&
                                  !names.contains(oldCategory)) {
                                names.add(oldCategory);
                              }

                              final dropdownValue =
                                  oldCategory != null &&
                                      names.contains(oldCategory)
                                  ? oldCategory
                                  : null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey(
                                    'category_${dropdownValue ?? 'empty'}',
                                  ),
                                  initialValue: dropdownValue,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Category',
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: Text(
                                    snapshot.hasError
                                        ? 'Could not load categories'
                                        : snapshot.connectionState ==
                                              ConnectionState.waiting
                                        ? 'Loading categories...'
                                        : names.isEmpty
                                        ? 'No categories found'
                                        : 'Select category',
                                  ),
                                  items: names
                                      .map(
                                        (name) => DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: names.isEmpty
                                      ? null
                                      : (value) {
                                          setDialogState(() {
                                            selectedCategory = value;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please select a category';
                                    }
                                    return null;
                                  },
                                ),
                              );
                            },
                          ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Book image',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 140,
                                  child: _buildImagePreview(
                                    book: book,
                                    imageBytes: selectedImageBytes,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final image = await ImagePicker()
                                          .pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 85,
                                          );

                                      if (image == null) return;

                                      final bytes = await image.readAsBytes();

                                      if (!context.mounted) return;

                                      setDialogState(() {
                                        selectedImage = image;
                                        selectedImageBytes = bytes;
                                      });
                                    } catch (error) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not select image: $error',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.image_outlined),
                                  label: Text(
                                    selectedImage == null
                                        ? 'Choose Image'
                                        : 'Change Image',
                                  ),
                                ),
                                if (selectedImage != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedImage = null;
                                        selectedImageBytes = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Remove selected image'),
                                  ),
                                if (book?.imageUrl.isNotEmpty == true &&
                                    selectedImage == null)
                                  const Text(
                                    'Current image will be kept.',
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          _textField(
                            priceController,
                            'Price',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final price = double.tryParse(value ?? '');

                              if (price == null ||
                                  !price.isFinite ||
                                  price < 0) {
                                return 'Enter a valid non-negative price';
                              }

                              return null;
                            },
                          ),

                          _textField(
                            stockController,
                            'Stock quantity',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final stock = int.tryParse(value ?? '');

                              if (stock == null || stock < 0) {
                                return 'Enter a valid non-negative quantity';
                              }

                              return null;
                            },
                          ),

                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Featured book'),
                            value: isFeatured,
                            onChanged: (value) {
                              setDialogState(() {
                                isFeatured = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final category = selectedCategory?.trim() ?? '';

                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      final stock = int.tryParse(stockController.text.trim());

                      if (price == null ||
                          !price.isFinite ||
                          price < 0 ||
                          stock == null ||
                          stock < 0) {
                        return;
                      }

                      final updatedBook = BookModel(
                        id: book?.id ?? '',
                        title: titleController.text.trim(),
                        author: authorController.text.trim(),
                        description: descriptionController.text.trim(),
                        category: category,
                        imageUrl: book?.imageUrl ?? '',
                        price: price,
                        stock: stock,
                        isFeatured: isFeatured,
                      );

                      Navigator.pop(
                        dialogContext,
                        _BookFormResult(
                          book: updatedBook,
                          imageBytes: selectedImageBytes,
                          imageName: selectedImage?.name,
                        ),
                      );
                    },
                    child: Text(book == null ? 'Add Book' : 'Save Changes'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null || !mounted) return;

      var imageUrl = result.book.imageUrl;

      if (result.imageBytes != null && result.imageName != null) {
        _showMessage('Uploading image to Cloudinary...');

        imageUrl = await _uploadBookImage(
          result.imageBytes!,
          result.imageName!,
        );
      }

      final savedBook = BookModel(
        id: result.book.id,
        title: result.book.title,
        author: result.book.author,
        description: result.book.description,
        category: result.book.category,
        imageUrl: imageUrl,
        price: result.book.price,
        stock: result.book.stock,
        isFeatured: result.book.isFeatured,
      );

      if (book == null) {
        await _bookService.addBook(savedBook);
      } else {
        await _bookService.updateBook(savedBook);
      }

      if (!mounted) return;

      _showMessage(
        book == null
            ? 'Book added successfully.'
            : 'Book updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not save the book: $error',
        duration: const Duration(seconds: 8),
      );
    } finally {
      titleController.dispose();
      authorController.dispose();
      descriptionController.dispose();
      priceController.dispose();
      stockController.dispose();
    }
  }

  Widget _buildImagePreview({
    required BookModel? book,
    required Uint8List? imageBytes,
  }) {
    if (imageBytes != null) {
      return Image.memory(imageBytes, fit: BoxFit.contain);
    }

    if (book != null && book.imageUrl.trim().isNotEmpty) {
      return Image.network(
        book.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, size: 44),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.menu_book_outlined, size: 44),
        SizedBox(height: 4),
        Text('No image selected', textAlign: TextAlign.center),
      ],
    );
  }

  Future<String> _uploadBookImage(Uint8List bytes, String originalName) async {
    // Cloudinary dashboard values.
    const cloudName = 'jpidw4oh';
    const uploadPreset = 'jpidw4oh';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: originalName),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 90),
    );

    final responseBody = await streamedResponse.stream.bytesToString();

    Map<String, dynamic> data;

    try {
      data = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Cloudinary returned an invalid response '
        '(${streamedResponse.statusCode}).',
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      final errorData = data['error'];

      final message = errorData is Map
          ? errorData['message']?.toString()
          : null;

      throw Exception(
        message ??
            'Cloudinary upload failed '
                '(${streamedResponse.statusCode}).',
      );
    }

    final imageUrl = data['secure_url']?.toString();

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return imageUrl;
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }

              return null;
            },
      ),
    );
  }

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<void> _confirmDelete(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Book?'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _bookService.deleteBook(book.id);

      if (!mounted) return;

      _showMessage('Book deleted successfully.');
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Could not delete the book: $error',
        duration: const Duration(seconds: 8),
      );
    }
  }
}

class _BookFormResult {
  const _BookFormResult({
    required this.book,
    required this.imageBytes,
    required this.imageName,
  });

  final BookModel book;
  final Uint8List? imageBytes;
  final String? imageName;
}
