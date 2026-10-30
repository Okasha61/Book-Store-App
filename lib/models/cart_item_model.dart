class CartItemModel {
  final String bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String category;
  final double price;
  final int quantity;
  final int stock;

  const CartItemModel({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.quantity,
    required this.stock,
  });

  factory CartItemModel.fromMap(String id, Map<String, dynamic> data) {
    return CartItemModel(
      bookId: id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'category': category,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }
}
