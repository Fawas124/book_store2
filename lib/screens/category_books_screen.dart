import 'package:book_store_2/screens/book/book_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';

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
      body: books.isEmpty
          ? const Center(child: Text('No books in this category'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return BookCard(
                  book: book,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: book),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
