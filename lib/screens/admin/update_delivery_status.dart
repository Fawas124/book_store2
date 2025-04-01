// screens/admin/update_delivery_status.dart
import 'package:book_store_2/models/order.dart' as order_model;
import 'package:book_store_2/services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateDeliveryStatusScreen extends StatelessWidget {
  final String orderId;
  final String userId;

  UpdateDeliveryStatusScreen({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Delivery Status')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: order_model.DeliveryStatus.values.map((status) {
            return ListTile(
              title: Text(_getStatusLabel(status)),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () async {
                await _updateStatus(context, status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // In OrderService
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> updateDeliveryStatus({
  required String orderId,
  required String userId,
  required order_model.DeliveryStatus newStatus,
  String? location,
  String? message,
}) async {
  try {
    debugPrint('Updating status for order $orderId to $newStatus');
    
    final update = {
      'deliveryStatus': newStatus.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (message != null) {
      update['deliveryUpdates'] = FieldValue.arrayUnion([
        {
          'timestamp': FieldValue.serverTimestamp(),
          'status': newStatus.toString().split('.').last,
          'message': message,
          'location': location,
        }
      ]);
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update(update);

    debugPrint('Status updated successfully');
  } catch (e, stack) {
    debugPrint('Error updating status: $e');
    debugPrint('Stack trace: $stack');
    rethrow;
  }
}

Future<void> _updateStatus(BuildContext context, order_model.DeliveryStatus status) async {
  try {
    final orderService = Provider.of<OrderService>(context, listen: false);
    await orderService.updateDeliveryStatus(
      orderId: orderId,
      userId: userId,
      newStatus: status,
      message: 'Status updated by admin',
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status updated successfully')),
    );
    
    Navigator.pop(context);
  } on FirebaseException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Firebase Error: ${e.code} - ${e.message}')),
    );
  } catch (e, stack) {
    debugPrint('Full error: $e');
    debugPrint('Stack trace: $stack');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

  String _getStatusLabel(order_model.DeliveryStatus status) {
    // Reuse the same method from OrderHistoryScreen
    return status.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match m) => ' ${m.group(1)}',
        ).trim();
  }
}