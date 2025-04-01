import 'package:book_store_2/models/book.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];
  String _searchType = 'title'; // Default search type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search books...',
            border: InputBorder.none,
          ),
          onChanged: (query) => _performSearch(query),
        ),
        actions: [
          // Search type dropdown
          DropdownButton<String>(
            value: _searchType,
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
                _performSearch(_searchController.text);
              });
            },
            items: <String>['title', 'author', 'genre']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value[0].toUpperCase() + value.substring(1),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _searchResults.isEmpty
          ? const Center(
              child: Text('Search for books by title, author or genre'),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                return ListTile(
                  leading: Image.network(
                    book.coverUrl,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.book, size: 50),
                  ),
                  title: Text(book.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.author),
                      if (book.genres.isNotEmpty)
                        Text(
                          book.genres.join(', '),
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Text('\$${book.price.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book: book),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() {
      _searchResults = Provider.of<BookService>(context, listen: false)
          .searchBooks(query, searchType: _searchType);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}