import 'package:flutter/material.dart';
import 'test/student_login_test.dart' as api_test;

import 'package:dio/dio.dart';
void main() {
  // api_test.main();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Text('Flutter Demo Home Page'),
    );
  }
}