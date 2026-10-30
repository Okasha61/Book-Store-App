class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final String imageUrl;
  final double price;
  final int stock;
  final bool isFeatured;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.stock,
    required this.isFeatured,
  });

  factory BookModel.fromMap(String id, Map<String, dynamic> data) {
    return BookModel(
      id: id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      isFeatured: data['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'price': price,
      'stock': stock,
      'isFeatured': isFeatured,
    };
  }
}
