import 'package:flutter/material.dart';
import 'package:test_app/screens/login.dart';
import 'package:test_app/screens/register.dart';
import 'package:test_app/screens/stock.dart';
import 'package:test_app/screens/orders.dart';
import 'package:test_app/screens/profile.dart';
import 'logged_in_layout.dart'; // Import the LoggedInLayout class

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login and Register Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // initialRoute: '/',
      // routes: {
      //   '/': (context) => LoginPage(),
      //   '/stocks': (context) => StockPage(),
      //   '/orders': (context) => OrdersPage(),
      //   '/profile': (context) => ProfilePage(),
      // },
      initialRoute: '/', // Set the initial route to '/'
      routes: {
        '/': (context) => LoginPage(),
        '/home': (context) => NavBar(),
      },
    );
  }
}
