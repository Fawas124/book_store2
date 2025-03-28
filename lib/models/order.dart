import 'package:book_store_2/models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
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
    
    // Debug print to check incoming data
    debugPrint('Parsing order data: $data');
    
    try {
      return Order(
        id: doc.id,
        userId: data['userId'] ?? '',
        items: (data['items'] as List? ?? []).map((item) {
          // Debug print for each item
          debugPrint('Processing order item: $item');
          
          return CartItem(
            book: Book(
              id: item['bookId'] ?? '',
              title: item['title'] ?? 'Unknown Title',
              author: item['author'] ?? 'Unknown Author',
              coverUrl: item['coverUrl'] ?? '',
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              description: item['description'] ?? '',
              genres: List<String>.from(item['genres'] ?? []),
              publishDate: DateTime.tryParse(item['publishDate'] ?? '') ?? DateTime.now(),
              isBestseller: item['isBestseller'] ?? false,
              rating: (item['rating'] as num?)?.toDouble() ?? 0.0,
              reviewCount: (item['reviewCount'] as num?)?.toInt() ?? 0,
            ),
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          );
        }).toList(),
        total: (data['total'] as num?)?.toDouble() ?? 0.0,
        date: (data['date'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] ?? 'Processing',
        shippingInfo: Map<String, String>.from(data['shippingInfo'] ?? {}),
      );
    } catch (e) {
      debugPrint('Error parsing order: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    // Debug print before conversion
    debugPrint('Converting order to map');
    
    final itemsMap = items.map((item) {
      return {
        'bookId': item.book.id,
        'title': item.book.title,
        'author': item.book.author,
        'coverUrl': item.book.coverUrl,
        'price': item.book.price,
        'quantity': item.quantity,
        'description': item.book.description,
        'genres': item.book.genres,
        'publishDate': item.book.publishDate.toIso8601String(),
        'isBestseller': item.book.isBestseller,
        'rating': item.book.rating,
        'reviewCount': item.book.reviewCount,
      };
    }).toList();

    final map = {
      'userId': userId,
      'items': itemsMap,
      'total': total,
      'date': firestore.Timestamp.fromDate(date), // Convert to Firestore Timestamp
      'status': status,
      'shippingInfo': shippingInfo,
    };

    // Debug print after conversion
    debugPrint('Converted order map: $map');
    return map;
  }

  @override
  String toString() {
    return 'Order{id: $id, userId: $userId, total: $total, status: $status, itemCount: ${items.length}}';
  }
}