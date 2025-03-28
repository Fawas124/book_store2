import 'package:flutter/material.dart';
import 'package:book_store_2/models/book.dart';
import '../widgets/book_card.dart';
import 'book/book_detail_screen.dart';

class CategoryBooksScreen extends StatelessWidget {
  final String category;
  final List<Book> books;

  const CategoryBooksScreen({
    super.key,
    required this.category,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BookCard(
              book: books[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: books[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}