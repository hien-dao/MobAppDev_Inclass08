import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import 'card_list_screen.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  @override
  Widget build(BuildContext context) {
    final folderRepo = Provider.of<FolderRepository>(context, listen: false);
    final cardRepo = Provider.of<CardRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
      ),
      body: FutureBuilder<List<Folder>>(
        future: folderRepo.getAllFolders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!;

          if (folders.isEmpty) {
            return const Center(child: Text('No folders found.'));
          }

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];

              return FutureBuilder<int>(
                future: cardRepo.getCardCountByFolder(folder.id!),
                builder: (context, countSnapshot) {
                  if (!countSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  final cardCount = countSnapshot.data!;

                  return ListTile(
                    title: Text(folder.folderName),
                    subtitle: Text('$cardCount cards'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Folder'),
                            content: Text(
                              'Delete "${folder.folderName}" and all its cards?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await folderRepo.deleteFolder(folder.id!);
                          setState(() {});
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CardListScreen(folder: folder),
                        ),
                      ).then((_) {
                        // In case card counts changed
                        setState(() {});
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
