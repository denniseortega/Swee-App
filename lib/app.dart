import 'screens/home_screen.dart';
import 'package:flutter/material.dart';


// import 'package:get_ip/get_ip.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Swee',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: HomePage());
  }
}