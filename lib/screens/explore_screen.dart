import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../widgets/book_card.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';
import 'book/book_detail_screen.dart';
import 'category_books_screen.dart';

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

  void _navigateToCategoryScreen(String title, List<Book> books) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBooksScreen(
          category: title,
          books: books,
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String title, List<String> categories, IconData icon) {
    final bookService = Provider.of<BookService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onSeeAll: () => _navigateToCategoryScreen(
            'All ${title.replaceFirst('Browse by ', '')}',
            title == 'Browse by Genre' ? bookService.books : bookService.books,
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // "All" category card
              CategoryCard(
                name: 'All',
                icon: icon,
                onTap: () => _navigateToCategoryScreen(
                  'All ${title.replaceFirst('Browse by ', '')}',
                  title == 'Browse by Genre'
                      ? bookService.books
                      : bookService.books,
                ),
              ),
              // Individual category cards
              ...categories.map((category) => CategoryCard(
                    name: category,
                    icon: icon,
                    onTap: () {
                      final filteredBooks = title == 'Browse by Genre'
                          ? bookService.books
                              .where((book) => book.genres.contains(category))
                              .toList()
                          : bookService.books
                              .where((book) => book.author == category)
                              .toList();

                      _navigateToCategoryScreen(category, filteredBooks);
                    },
                  )),
            ],
          ),
        ),
      ],
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

    // Get all unique genres
    final allGenres =
        bookService.books.expand((book) => book.genres).toSet().toList();

    // Get all unique authors
    final allAuthors =
        bookService.books.map((book) => book.author).toSet().toList();

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
                  // Search bar (keep existing)
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

                  // Genres Section
                  _buildCategorySection(
                    'Browse by Genre',
                    allGenres,
                    Icons.category,
                  ),

                  // Authors Section
                  _buildCategorySection(
                    'Browse by Author',
                    allAuthors,
                    Icons.person,
                  ),

                  // Best Selling Section (keep existing)
                  SectionHeader(
                    title: 'Best Selling Books',
                    onSeeAll: () => _navigateToCategoryScreen(
                      'Bestsellers',
                      bestsellers,
                    ),
                  ),
                  _buildBookList(bestsellers),

                  // New Arrivals Section (keep existing)
                  SectionHeader(
                    title: 'New Arrivals',
                    onSeeAll: () => _navigateToCategoryScreen(
                      'New Arrivals',
                      newArrivals,
                    ),
                  ),
                  _buildBookList(newArrivals),
                ],
              ),
            ),
    );
  }
}
