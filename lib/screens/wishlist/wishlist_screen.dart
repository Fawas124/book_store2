import 'package:book_store_2/services/book_service.dart';
import 'package:book_store_2/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  // In wishlist_screen.dart
  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<BookService>(context).wishlist;

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: SingleChildScrollView(
        // Add this
        child: ConstrainedBox(
          // And this
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: wishlist.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Your wishlist is empty'),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true, // Add this
                  physics: NeverScrollableScrollPhysics(), // Add this
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: wishlist.length,
                  itemBuilder: (context, index) => BookCard(
                    book: wishlist[index],
                    onTap: () {/* Navigation */},
                  ),
                ),
        ),
      ),
    );
  }
}
