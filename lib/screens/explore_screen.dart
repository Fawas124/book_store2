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
  // Sorting state for each section
  String _bestsellerSortBy = 'none';
  bool _bestsellerAscending = true;
  String _newArrivalSortBy = 'none';
  bool _newArrivalAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookService>(context, listen: false).fetchBooks();
    });
  }

  List<Book> _sortBooks(List<Book> books, String sortBy, bool ascending) {
    List<Book> sortedBooks = List.from(books);

    switch (sortBy) {
      case 'price':
        sortedBooks.sort((a, b) => ascending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'rating':
        sortedBooks.sort((a, b) => ascending
            ? a.rating.compareTo(b.rating)
            : b.rating.compareTo(a.rating));
        break;
      case 'releaseDate':
        sortedBooks.sort((a, b) => ascending
            ? a.publishDate.compareTo(b.publishDate)
            : b.publishDate.compareTo(a.publishDate));
        break;
      default:
        // No sorting
        break;
    }

    return sortedBooks;
  }

  PopupMenuButton<String> _buildSortButton(
    String currentSortBy,
    bool currentAscending,
    Function(String) onSortChanged,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Colors.grey[700]),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'none', child: Text('Default Order')),
        const PopupMenuItem(value: 'price', child: Text('Sort by Price')),
        const PopupMenuItem(value: 'rating', child: Text('Sort by Rating')),
        const PopupMenuItem(
            value: 'releaseDate', child: Text('Sort by Release Date')),
      ],
      onSelected: (value) {
        if (value == currentSortBy) {
          onSortChanged('none'); // Reset if same option selected
        } else {
          onSortChanged(value);
        }
      },
    );
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
            bookService.books,
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
                  bookService.books,
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

    // Get and sort bestsellers
    final bestsellers = _sortBooks(
      bookService.books.where((b) => b.isBestseller).toList(),
      _bestsellerSortBy,
      _bestsellerAscending,
    );

    // Get and sort new arrivals
    final newArrivals = _sortBooks(
      bookService.books
          .where((b) => b.publishDate.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ))
          .toList(),
      _newArrivalSortBy,
      _newArrivalAscending,
    );

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
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.dstATop,
                  ),
                ),
              ),
              child: SingleChildScrollView(
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

                    // Best Selling Section with sorting
                    SectionHeader(
                      title: 'Best Selling Books',
                      onSeeAll: () => _navigateToCategoryScreen(
                        'Bestsellers',
                        bestsellers,
                      ),
                      trailing: _buildSortButton(
                        _bestsellerSortBy,
                        _bestsellerAscending,
                        (value) => setState(() {
                          _bestsellerSortBy = value;
                          _bestsellerAscending = value != 'none';
                        }),
                      ),
                    ),
                    _buildBookList(bestsellers),

                    // New Arrivals Section with sorting
                    SectionHeader(
                      title: 'New Arrivals',
                      onSeeAll: () => _navigateToCategoryScreen(
                        'New Arrivals',
                        newArrivals,
                      ),
                      trailing: _buildSortButton(
                        _newArrivalSortBy,
                        _newArrivalAscending,
                        (value) => setState(() {
                          _newArrivalSortBy = value;
                          _newArrivalAscending = value != 'none';
                        }),
                      ),
                    ),
                    _buildBookList(newArrivals),
                  ],
                ),
              ),
            ),
    );
  }
}
