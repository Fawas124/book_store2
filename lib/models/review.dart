import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final String text;
  final int rating;
  final DateTime date;

  Review({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.date,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookId: data['bookId'],
      userId: data['userId'],
      userName: data['userName'],
      text: data['text'],
      rating: data['rating'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'rating': rating,
      'date': Timestamp.fromDate(date),
    };
  }
}