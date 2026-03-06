import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import 'add_edit_card_screen.dart';

class CardListScreen extends StatefulWidget {
  final Folder folder;

  const CardListScreen({super.key, required this.folder});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  Widget build(BuildContext context) {
    final cardRepo = Provider.of<CardRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folder.folderName} Cards'),
      ),
      body: FutureBuilder<List<PlayingCard>>(
        future: cardRepo.getCardsByFolderId(widget.folder.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cards = snapshot.data!;

          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this folder.'));
          }

          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];

              return Card(
                child: ListTile(
                  leading: card.imageUrl != null && card.imageUrl!.isNotEmpty
                      ? Image.network(
                          card.imageUrl!,
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image),
                  title: Text(card.cardName),
                  subtitle: Text(card.suit),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditCardScreen(card: card),
                            ),
                          ).then((saved) {
                            if (saved == true) {
                              setState(() {});
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Card'),
                              content: Text(
                                'Are you sure you want to delete ${card.cardName}?',
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
                            await cardRepo.deleteCard(card.id!);
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddEditCardScreen(initialFolder: widget.folder),
            ),
          ).then((saved) {
            if (saved == true) {
              setState(() {});
            }
          });
        },
      ),
    );
  }
}
