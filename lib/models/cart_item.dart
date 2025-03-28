import 'package:book_store_2/models/order.dart';

import '../models/book.dart';

class CartItem {
  final Book book;
  int quantity;

  CartItem({
    required this.book,
    this.quantity = 1,
  });

  static Order fromMap(Map<String, dynamic> item) {
    if (item.containsKey('orderId') && item.containsKey('details')) {
      return Order(
        id: item['id'],
        userId: item['userId'],
        items: item['items'],
        total: item['total'],
        date: DateTime.parse(item['date']),
        status: item['status'],
      );
    } else {
      throw ArgumentError('Invalid map data for creating an Order.');
    }
  }
}