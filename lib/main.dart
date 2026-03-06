import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database_helper.dart';
import 'repositories/folder_repository.dart';
import 'repositories/card_repository.dart';
import 'screens/folder_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure DB is created and prepopulated before UI
  await DatabaseHelper.instance.database;

  runApp(const CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  const CardOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FolderRepository>(
          create: (_) => FolderRepository(),
        ),
        Provider<CardRepository>(
          create: (_) => CardRepository(),
        ),
      ],
      child: MaterialApp(
        title: 'Card Organizer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        home: const FolderListScreen(),
      ),
    );
  }
}
