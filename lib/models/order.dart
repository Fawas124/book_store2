import 'package:book_store_2/models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status;
  final Map<String, String>? shippingInfo;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.date,
    this.status = 'Processing',
    this.shippingInfo,
  });

  factory Order.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'],
      items: (data['items'] as List).map((item) => CartItem(
        book: Book(
          id: item['bookId'],
          title: item['title'],
          author: item['author'],
          coverUrl: item['coverUrl'],
          price: item['price']?.toDouble() ?? 0.0,
          description: item['description'] ?? '',
          genres: List<String>.from(item['genres'] ?? []),
          publishDate: DateTime.parse(item['publishDate'] ?? DateTime.now().toString()),
        ),
        quantity: item['quantity'] ?? 1,
      )).toList(),
      total: data['total']?.toDouble() ?? 0.0,
      date: (data['date'] as firestore.Timestamp).toDate(),
      status: data['status'] ?? 'Processing',
      shippingInfo: Map<String, String>.from(data['shippingInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => {
        'bookId': item.book.id,
        'title': item.book.title,
        'author': item.book.author,
        'coverUrl': item.book.coverUrl,
        'price': item.book.price,
        'quantity': item.quantity,
        'description': item.book.description,
        'genres': item.book.genres,
        'publishDate': item.book.publishDate.toIso8601String(),
      }).toList(),
      'total': total,
      'date': date,
      'status': status,
      'shippingInfo': shippingInfo,
    };
  }
}