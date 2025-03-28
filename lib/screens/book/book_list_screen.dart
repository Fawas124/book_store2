import 'package:book_store_2/models/book.dart';
import 'package:flutter/material.dart';

class BookListScreen extends StatelessWidget {
  final String title;
  final List<Book> books;

  const BookListScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            leading: Image.network(book.coverUrl, width: 50),
            title: Text(book.title),
            subtitle: Text('${book.author} • \$${book.price}'),
          );
        },
      ),
    );
  }
}