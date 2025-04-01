import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart' show DeliveryStatus, Order; // Import only Order to avoid conflict
import '../models/order_enums.dart' as orderEnums; // Aliased import

class DeliveryUpdate {
  final DateTime timestamp;
  final orderEnums.DeliveryStatus status;
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
      'status': status.name, // Using .name
      'location': location,
      'message': message,
    };
  }
}

class OrderService with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> createOrder(
    List<CartItem> items,
    double total, {
    required Map<String, String> shippingInfo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final mainOrderRef = _firestore.collection('orders').doc();
      final userOrderRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(mainOrderRef.id);

      final order = Order(
        id: mainOrderRef.id,
        userId: user.uid,
        items: items,
        total: total,
        date: DateTime.now(),
        status: 'Processing',
        shippingInfo: shippingInfo,
        deliveryStatus: DeliveryStatus.processing,
      );

      final batch = _firestore.batch();
      batch.set(mainOrderRef, order.toFirestoreMap());
      batch.set(userOrderRef, order.toFirestoreMap());

      await batch.commit();
      notifyListeners();
      return mainOrderRef.id;
    } catch (e) {
      debugPrint('Order creation failed: $e');
      rethrow;
    }
  }

  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  Stream<List<Order>> getUserOrdersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromFirestore).toList());
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      return doc.exists ? Order.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  Future<void> updateDeliveryStatus({
    required String orderId,
    required String userId,
    required DeliveryStatus newStatus,
    String? location,
    String? message,
  }) async {
    try {
      final update = DeliveryUpdate(
        timestamp: DateTime.now(),
        status: orderEnums.DeliveryStatus.values.byName(newStatus.name), // Convert to correct type
        location: location,
        message: message,
      );

      await _firestore.runTransaction((transaction) async {
        final userOrderRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);

        final mainOrderRef = _firestore.collection('orders').doc(orderId);

        final updateData = {
          'deliveryStatus': newStatus.name, // Using .name
          'deliveryUpdates': firestore.FieldValue.arrayUnion([update.toMap()]),
        };

        transaction.update(userOrderRef, updateData);
        transaction.update(mainOrderRef, updateData);
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Delivery status update failed: $e');
      rethrow;
    }
  }

  Future<void> addTrackingInfo({
    required String orderId,
    required String userId,
    required String trackingNumber,
    required String carrier,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userOrderRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('orders')
            .doc(orderId);

        final mainOrderRef = _firestore.collection('orders').doc(orderId);

        final updateData = {
          'trackingNumber': trackingNumber,
          'carrier': carrier,
          'deliveryStatus': DeliveryStatus.shipped.name, // Using .name
        };

        transaction.update(userOrderRef, updateData);
        transaction.update(mainOrderRef, updateData);
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Tracking info update failed: $e');
      rethrow;
    }
  }
}
