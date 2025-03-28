import 'package:book_store_2/models/review.dart';
import 'package:book_store_2/services/auth_service.dart';
import 'package:book_store_2/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../services/review_service.dart';
import '../../widgets/review_tile.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  
  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = Provider.of<ReviewService>(context, listen: false)
        .getReviewsForBook(widget.book.id);
  }

  @override
  Widget build(BuildContext context) {
    final bookService = Provider.of<BookService>(context);
    final isInWishlist = bookService.isInWishlist(widget.book);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist ? Icons.bookmark : Icons.bookmark_border,
              color: isInWishlist ? Colors.blue : null,
            ),
            onPressed: () => bookService.toggleWishlist(widget.book),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 2/3,
              child: Image.network(
                widget.book.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${widget.book.author}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${widget.book.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<double>(
                    future: Provider.of<ReviewService>(context)
                        .getAverageRating(widget.book.id),
                    builder: (context, snapshot) {
                      final avgRating = snapshot.data ?? widget.book.rating;
                      return Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(avgRating.toStringAsFixed(1)),
                          const SizedBox(width: 8),
                          Text('(${widget.book.reviewCount} reviews)'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.book.description),
                  const SizedBox(height: 16),
                  if (widget.book.genres.isNotEmpty) ...[
                    Text(
                      'Genres',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.book.genres
                          .map((genre) => Chip(label: Text(genre)))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Review>>(
                    future: _reviewsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No reviews yet');
                      }
                      return Column(
                        children: [
                          ...snapshot.data!.map((review) => ReviewTile(review: review)),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  if (Provider.of<AuthService>(context).user != null) ...[
                    const Text(
                      'Add Your Review',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          IconButton(
                            icon: Icon(
                              i <= _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => setState(() => _rating = i),
                          ),
                      ],
                    ),
                    TextField(
                      controller: _reviewController,
                      decoration: const InputDecoration(
                        hintText: 'Write your review...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _rating > 0 ? _submitReview : null,
                      child: const Text('Submit Review'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<CartService>(
          builder: (context, cart, child) {
            return ElevatedButton(
              onPressed: () {
                cart.addToCart(widget.book);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              },
              child: const Text('Add to Cart'),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    try {
      await Provider.of<ReviewService>(context, listen: false).addReview(
        bookId: widget.book.id,
        text: _reviewController.text,
        rating: _rating,
      );
      setState(() {
        _reviewsFuture = Provider.of<ReviewService>(context, listen: false)
            .getReviewsForBook(widget.book.id);
        _reviewController.clear();
        _rating = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}