import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  // AppUser? _user;
  AppUser? _currentUser; // Define _currentUser
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? get user => _currentUser;

  AuthService() {
    _auth.authStateChanges().listen((User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
      } else {
        await _fetchUserData(fbUser.uid);
      }
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Add these methods to your AuthService class

  Future<void> updateUserProfile({
    required String displayName,
    required String email,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updateEmail(email);
      await _fetchUserData(_auth.currentUser!.uid); // Refresh user data
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> addShippingAddress(Map<String, dynamic> address) async {
    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser?.uid);

      // Get current addresses
      final userData = await userDoc.get();
      List<Map<String, dynamic>> currentAddresses = [];

      if (userData.exists && userData.data()?['shippingAddresses'] != null) {
        currentAddresses = List<Map<String, dynamic>>.from(
            userData.data()!['shippingAddresses']);
      }

      // Add new address
      currentAddresses.add(address);

      // Update Firestore
      await userDoc.update({
        'shippingAddresses': currentAddresses,
      });

      // Refresh user data
      await _fetchUserData(_auth.currentUser!.uid);
    } catch (e) {
      throw Exception('Failed to add shipping address: $e');
    }
  }

  Future<void> removeShippingAddress(int index) async {
    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser?.uid);
      final userData = await userDoc.get();

      if (userData.exists && userData.data()?['shippingAddresses'] != null) {
        List<Map<String, dynamic>> addresses = List<Map<String, dynamic>>.from(
            userData.data()!['shippingAddresses']);

        if (index >= 0 && index < addresses.length) {
          addresses.removeAt(index);

          await userDoc.update({
            'shippingAddresses': addresses,
          });

          await _fetchUserData(_auth.currentUser!.uid);
        }
      }
    } catch (e) {
      throw Exception('Failed to remove shipping address: $e');
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc);
      } else {
        _currentUser = AppUser.fromFirebaseUser(_auth.currentUser!);
        await _firestore.collection('users').doc(uid).set(_currentUser!.toMap());
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _currentUser = null;
    }
  }


  Future<void> updateShippingAddress(
      int index, Map<String, dynamic> newAddress) async {
    try {
      final userDoc =
          _firestore.collection('users').doc(_auth.currentUser?.uid);
      final user = await userDoc.get();

      if (!user.exists) {
        print('DEBUG: User document does not exist');
        return;
      }

      final data = user.data();
      if (data == null) {
        print('DEBUG: User data is null');
        return;
      }

      final addresses =
          List<Map<String, dynamic>>.from(data['shippingAddresses'] ?? []);
      print('DEBUG: Current addresses before update: $addresses');

      if (index < addresses.length) {
        addresses[index] = newAddress;
        await userDoc.update({
          'shippingAddresses': addresses,
        });
        print('DEBUG: Addresses after update: $addresses');
        await _fetchUserData(_auth.currentUser!.uid);
      }
    } catch (e) {
      print('DEBUG: Error updating address: $e');
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> method) async {
    try {
      final userDoc =
          _firestore.collection('users').doc(_auth.currentUser?.uid);
      await userDoc.update({
        'paymentMethods': FieldValue.arrayUnion([method]),
      });
      await _fetchUserData(_auth.currentUser!.uid); // Refresh user data
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  Future<void> removePaymentMethod(int index) async {
    try {
      final userDoc =
          _firestore.collection('users').doc(_auth.currentUser?.uid);
      final user = await userDoc.get();
      final methods = List.from(user.data()?['paymentMethods'] ?? []);
      if (index < methods.length) {
        methods.removeAt(index);
        await userDoc.update({
          'paymentMethods': methods,
        });
        await _fetchUserData(_auth.currentUser!.uid); // Refresh user data
      }
    } catch (e) {
      throw Exception('Failed to remove payment method: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
