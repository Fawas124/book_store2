// models/order_enums.dart
enum DeliveryStatus {
  processing,
  confirmed,
  packaged,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  cancelled,
  returned
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
      'timestamp': timestamp,
      'status': status.name, // Using .name instead of toString()
      'location': location,
      'message': message,
    };
  }

  factory DeliveryUpdate.fromMap(Map<String, dynamic> map) {
    return DeliveryUpdate(
      timestamp: map['timestamp'].toDate(),
      status: DeliveryStatus.values.byName(map['status']), // Dart 2.15+ enum lookup
      location: map['location'],
      message: map['message'],
    );
  }
}