import 'package:book_store_2/models/book.dart';
import 'package:flutter/material.dart';

class BookListScreen extends StatefulWidget {
  final String title;
  final List<Book> books;

  const BookListScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  // Current sort option (default: none/original order)
  String _sortBy = 'none';
  bool _ascending = true;

  // Sort the books based on selected criteria
  List<Book> get _sortedBooks {
    List<Book> sortedBooks = List.from(widget.books);

    switch (_sortBy) {
      case 'price':
        sortedBooks.sort((a, b) => _ascending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'rating': // Assuming 'popularity' is represented by 'rating'
        sortedBooks.sort((a, b) => _ascending
            ? a.rating.compareTo(b.rating)
            : b.rating.compareTo(a.rating));
        break;
      case 'releaseDate': // Assuming Book has a 'releaseDate' (DateTime)
        sortedBooks.sort((a, b) => _ascending
            ? a.releaseDate.compareTo(b.releaseDate)
            : b.releaseDate.compareTo(a.releaseDate));
        break;
      default:
        // No sorting (original order)
        break;
    }

    return sortedBooks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Sort dropdown button in AppBar
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == _sortBy) {
                  // Toggle ascending/descending if same option is selected
                  _ascending = !_ascending;
                } else {
                  // New sort option, default to ascending
                  _sortBy = value;
                  _ascending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'none',
                child: Text('Default Order'),
              ),
              const PopupMenuItem(
                value: 'price',
                child: Text('Sort by Price'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Popularity'),
              ),
              const PopupMenuItem(
                value: 'releaseDate',
                child: Text('Sort by Release Date'),
              ),
            ],
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _sortedBooks.length,
        itemBuilder: (context, index) {
          final book = _sortedBooks[index];
          return ListTile(
            leading: Image.network(book.coverUrl, width: 50),
            title: Text(book.title),
            subtitle: Text('${book.author} • \$${book.price}'),
            trailing: _sortBy == 'rating'
                ? Text('⭐ ${book.rating}')
                : null,
          );
        },
      ),
    );
  }
}