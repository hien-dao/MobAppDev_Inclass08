import 'package:flutter/material.dart';
import 'package:inclass08/screens/folder_screen.dart';
import 'database_helper.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Demo',
      theme: ThemeData( primarySwatch:Colors.blue, ),
      home: FoldersScreen(), 
    );
  }
}

