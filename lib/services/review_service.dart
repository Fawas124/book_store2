import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';

class ReviewService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Review>> getReviewsForBook(String bookId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
  }

  Future<void> addReview({
    required String bookId,
    required String text,
    required int rating,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('reviews').add({
      'bookId': bookId,
      'userId': user.uid,
      'userName': user.displayName ?? 'Anonymous',
      'text': text,
      'rating': rating,
      'date': Timestamp.now(),
    });
  }

  Future<double> getAverageRating(String bookId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('bookId', isEqualTo: bookId)
        .get();
    
    if (snapshot.docs.isEmpty) return 0.0;
    
    final total = snapshot.docs.fold(0, (sum, doc) {
      return sum + (doc.data()['rating'] as int);
    });
    
    return total / snapshot.docs.length;
  }
}