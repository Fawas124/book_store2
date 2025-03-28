import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Book> _books = [];
  List<Book> _wishlist = [];
  bool _isLoading = false;

  List<Book> get books => _books;
  List<Book> get wishlist => _wishlist;
  bool get isLoading => _isLoading;

  Future<void> fetchBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.googleapis.com/books/v1/volumes?q=book&maxResults=40&orderBy=newest&key=AIzaSyAGgudiHnZYnHEG_xPd93exiQMsCHmpm64'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _books = (data['items'] as List)
            .map((item) => Book.fromJson({
                  ...item['volumeInfo'],
                  'id': item['id'],
                  'saleInfo': item['saleInfo'],
                }))
            .toList();
      }

      await _loadWishlist();
    } catch (e) {
      debugPrint('Error fetching books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .get();

      // If we have full book data from fetchBooks, use that
      if (_books.isNotEmpty) {
        _wishlist = _books.where((book) {
          return snapshot.docs.any((doc) => doc.id == book.id);
        }).toList();
      } else {
        // Fallback if we only have wishlist data
        _wishlist = snapshot.docs.map((doc) {
          return Book(
            id: doc.id,
            title: doc.data()['title'] ?? '',
            author: doc.data()['author'] ?? 'Unknown author',
            description: '',
            coverUrl: doc.data()['coverUrl'] ?? '',
            price: 0.0,
            genres: [],
            publishDate: DateTime.now(),
            isBestseller: false,
            rating: 0.0,
            reviewCount: 0,
          );
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  Future<void> toggleWishlist(Book book) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final wishlistRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(book.id);

      if (isInWishlist(book)) {
        _wishlist.removeWhere((b) => b.id == book.id);
        await wishlistRef.delete();
      } else {
        await wishlistRef.set({
          'bookId': book.id,
          'addedAt': FieldValue.serverTimestamp(),
          'title': book.title,
          'author': book.author,
          'coverUrl': book.coverUrl,
        });
        _wishlist.add(book);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    }
  }

  bool isInWishlist(Book book) {
    return _wishlist.any((w) => w.id == book.id);
  }

  List<Book> searchBooks(String query) {
    return _books
        .where((book) =>
            book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void loadWishlist() {}
}
