import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<Map<String, dynamic>> shippingAddresses;
  final List<Map<String, dynamic>> paymentMethods;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.shippingAddresses = const [],
    this.paymentMethods = const [],
  });

  factory AppUser.fromFirebaseUser(fb.User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      shippingAddresses: List<Map<String, dynamic>>.from(data['shippingAddresses'] ?? []),
      paymentMethods: List<Map<String, dynamic>>.from(data['paymentMethods'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'shippingAddresses': shippingAddresses,
      'paymentMethods': paymentMethods,
    };
  }
}