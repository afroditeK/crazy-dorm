import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(CrazyDormApp());
}

class CrazyDormApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crazy Dorm',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        // Add more routes as needed
      },
    );
  }
}
