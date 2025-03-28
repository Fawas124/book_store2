import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/book_card.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';
import 'book/book_detail_screen.dart';
import 'category_books_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExploreScreen();
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookService>(context, listen: false).fetchBooks();
    });
  }

  Widget _buildBookList(List<Book> books) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No books available')),
      );
    }

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          return BookCard(
            book: books[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: books[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _filterByCategory(String category) {
    final bookService = Provider.of<BookService>(context, listen: false);
    List<Book> filteredBooks;

    if (category == 'All') {
      filteredBooks = bookService.books;
    } else if (category == 'Bestsellers') {
      filteredBooks = bookService.books.where((b) => b.isBestseller).toList();
    } else if (category == 'New Arrivals') {
      filteredBooks = bookService.books
          .where((b) => b.publishDate.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ))
          .toList();
    } else {
      filteredBooks = bookService.books
          .where((book) => book.genres.contains(category))
          .toList();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBooksScreen(
          category: category,
          books: filteredBooks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookService = Provider.of<BookService>(context);
    final bestsellers = bookService.books.where((b) => b.isBestseller).toList();
    final newArrivals = bookService.books
        .where((b) => b.publishDate.isAfter(
              DateTime.now().subtract(const Duration(days: 30)),
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Store'),
        centerTitle: true,
      ),
      body: bookService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        height: 50,
                        child: const Row(
                          children: [
                            Icon(Icons.search),
                            SizedBox(width: 8),
                            Text('Search for books...'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Categories Section
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        CategoryCard(
                          name: 'All Books',
                          icon: Icons.book,
                          onTap: () => _filterByCategory('All'),
                        ),
                        CategoryCard(
                          name: 'Horror',
                          icon: Icons.holiday_village,
                          onTap: () => _filterByCategory('Horror'),
                        ),
                        CategoryCard(
                          name: 'Comics',
                          icon: Icons.auto_awesome,
                          onTap: () => _filterByCategory('Comics'),
                        ),
                        CategoryCard(
                          name: 'History',
                          icon: Icons.history,
                          onTap: () => _filterByCategory('History'),
                        ),
                        CategoryCard(
                          name: 'Fiction',
                          icon: Icons.auto_stories,
                          onTap: () => _filterByCategory('Fiction'),
                        ),
                      ],
                    ),
                  ),

                  // Best Selling Section
                  SectionHeader(
                    title: 'Best Selling Books',
                    onSeeAll: () => _filterByCategory('Bestsellers'),
                  ),
                  _buildBookList(bestsellers),

                  // New Arrivals Section
                  SectionHeader(
                    title: 'New Arrivals',
                    onSeeAll: () => _filterByCategory('New Arrivals'),
                  ),
                  _buildBookList(newArrivals),
                ],
              ),
            ),
    );
  }
}