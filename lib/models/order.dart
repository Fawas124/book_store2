import 'package:book_store_2/models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'cart_item.dart';

enum DeliveryStatus {
  processing,
  confirmed,
  packaged,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  cancelled,
  returned,
}

class DeliveryUpdate {
  final DateTime timestamp;
  final DeliveryStatus status;
  final String? location;
  final String? message;

  DeliveryUpdate({
    required this.timestamp,
    required this.status,
    this.location,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': firestore.Timestamp.fromDate(timestamp),
      'status': status.name,
      'location': location,
      'message': message,
    };
  }

  factory DeliveryUpdate.fromMap(Map<String, dynamic> map) {
    return DeliveryUpdate(
      timestamp: (map['timestamp'] as firestore.Timestamp).toDate(),
      status: DeliveryStatus.values.byName(map['status']),
      location: map['location'],
      message: map['message'],
    );
  }
}

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String status;
  final Map<String, String>? shippingInfo;
  final DeliveryStatus deliveryStatus;
  final List<DeliveryUpdate> deliveryUpdates;
  final String? trackingNumber;
  final String? carrier;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.date,
    this.status = 'Processing',
    this.shippingInfo,
    this.deliveryStatus = DeliveryStatus.processing,
    this.deliveryUpdates = const [],
    this.trackingNumber,
    this.carrier,
  });

  factory Order.fromFirestore(firestore.DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      
      // Validate required fields
      if (data['userId'] == null) {
        throw Exception('Missing userId field in order document');
      }

      return Order(
        id: doc.id,
        userId: data['userId'] as String,
        items: (data['items'] as List? ?? []).map((item) {
          try {
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
          } catch (e) {
            debugPrint('Error parsing cart item: $item, error: $e');
            throw Exception('Invalid cart item format');
          }
        }).toList(),
        total: (data['total'] as num?)?.toDouble() ?? 0.0,
        date: (data['date'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] ?? 'Processing',
        shippingInfo: Map<String, String>.from(data['shippingInfo'] ?? {}),
        deliveryStatus: data['deliveryStatus'] != null 
            ? DeliveryStatus.values.byName(data['deliveryStatus'])
            : DeliveryStatus.processing,
        deliveryUpdates: (data['deliveryUpdates'] as List? ?? [])
            .map((e) => DeliveryUpdate.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        trackingNumber: data['trackingNumber'],
        carrier: data['carrier'],
      );
    } catch (e, stack) {
      debugPrint('Error parsing order ${doc.id}: $e');
      debugPrint('Stack trace: $stack');
      throw Exception('Failed to parse order document');
    }
  }

  Map<String, dynamic> toFirestoreMap() {
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
        'isBestseller': item.book.isBestseller,
        'rating': item.book.rating,
        'reviewCount': item.book.reviewCount,
      }).toList(),
      'total': total,
      'date': firestore.Timestamp.fromDate(date),
      'status': status,
      'shippingInfo': shippingInfo,
      'deliveryStatus': deliveryStatus.name,
      'deliveryUpdates': deliveryUpdates.map((e) => e.toMap()).toList(),
      'trackingNumber': trackingNumber,
      'carrier': carrier,
    };
  }

  // Status helper methods
  bool get isShipped => deliveryStatus.index >= DeliveryStatus.shipped.index;
  bool get isDelivered => deliveryStatus == DeliveryStatus.delivered;
  bool get isCancelled => deliveryStatus == DeliveryStatus.cancelled;
  bool get isProcessing => deliveryStatus == DeliveryStatus.processing;
  bool get isReturned => deliveryStatus == DeliveryStatus.returned;

  String get statusLabel {
    switch (deliveryStatus) {
      case DeliveryStatus.processing:
        return 'Processing';
      case DeliveryStatus.confirmed:
        return 'Order Confirmed';
      case DeliveryStatus.packaged:
        return 'Packaged';
      case DeliveryStatus.shipped:
        return 'Shipped';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.outForDelivery:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.returned:
        return 'Returned';
    }
  }

  String get formattedDate => DateFormat('MMM dd, yyyy - hh:mm a').format(date);

  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  @override
  String toString() {
    return 'Order{id: $id, userId: $userId, total: $total, '
           'status: $status, delivery: $deliveryStatus, '
           'items: ${items.length}, tracking: $trackingNumber}';
  }
}