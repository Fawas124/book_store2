import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

class OrderService with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<String> createOrder(List<CartItem> items, double total,
      {required Map<String, String> shippingInfo}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Create document references
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
        shippingInfo: shippingInfo,
      );

      final orderData = {
        ...order.toMap(),
        'date': firestore.Timestamp.fromDate(order.date), // Convert to Firestore Timestamp
      };

      // Write to both collections in a batch to ensure atomic operation
      final batch = _firestore.batch();
      batch.set(mainOrderRef, orderData);
      batch.set(userOrderRef, orderData);

      await batch.commit();

      debugPrint('Order created successfully with ID: ${mainOrderRef.id}');
      notifyListeners();
      return mainOrderRef.id;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  Future<List<Order>> getUserOrders(String userId) async {
    try {
      debugPrint('Fetching orders for user: $userId');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('orders')
          .orderBy('date', descending: true)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} orders');
      
      final orders = querySnapshot.docs.map((doc) {
        debugPrint('Order data: ${doc.data()}');
        return Order.fromFirestore(doc);
      }).toList();

      return orders;
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

  // Optional: Get single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }
}