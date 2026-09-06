import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const RestaurantQueueApp());
}

class RestaurantQueueApp extends StatelessWidget {
  const RestaurantQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Queue App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
