import 'package:book_store_2/app.dart';
import 'package:book_store_2/firebase_options.dart';
import 'package:book_store_2/screens/profile/theme_provider.dart' as profile;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/book_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/review_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => profile.ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => ReviewService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: const BookstoreApp(),
    ),
  );
}