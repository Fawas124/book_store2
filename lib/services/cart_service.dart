import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/cart_item.dart';

class CartService with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  double get totalPrice => _items.fold(0, (sum, item) => sum + (item.book.price * item.quantity));

  void addToCart(Book book) {
    final existingIndex = _items.indexWhere((item) => item.book.id == book.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(book: book));
    }
    notifyListeners();
  }

  void removeFromCart(String bookId) {
    _items.removeWhere((item) => item.book.id == bookId);
    notifyListeners();
  }

  void updateQuantity(String bookId, int quantity) {
    final index = _items.indexWhere((item) => item.book.id == bookId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}