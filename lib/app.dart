import 'package:book_store_2/screens/book/book_detail_screen.dart';
import 'package:book_store_2/screens/book/search_screen.dart';
import 'package:book_store_2/services/auth_service.dart';
import 'package:book_store_2/services/book_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/book.dart'; // Import the Book class

class BookstoreApp extends StatelessWidget {
  const BookstoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookstore App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/search': (context) => const SearchScreen(),
        '/bookDetail': (context) => BookDetailScreen(
            book: ModalRoute.of(context)!.settings.arguments as Book),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return authService.user == null ? const LoginScreen() : const MainWrapper();
  }
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookService>(context, listen: false).fetchBooks();
      Provider.of<BookService>(context, listen: false).loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
