import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/folder.dart';
import '../repositories/card_repository.dart';
import '../repositories/folder_repository.dart';

class AddEditCardScreen extends StatefulWidget {
  final PlayingCard? card;     // null = add mode
  final Folder? initialFolder; // optional preselected folder

  const AddEditCardScreen({
    super.key,
    this.card,
    this.initialFolder,
  });

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _imageController;

  String? _selectedSuit;
  int? _selectedFolderId;

  final suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];

  @override
  void initState() {
    super.initState();

    final card = widget.card;

    _nameController = TextEditingController(text: card?.cardName ?? '');
    _imageController = TextEditingController(text: card?.imageUrl ?? '');

    _selectedSuit = card?.suit ?? suits.first;
    _selectedFolderId = card?.folderId ?? widget.initialFolder?.id;
  }

  @override
  Widget build(BuildContext context) {
    final cardRepo = Provider.of<CardRepository>(context, listen: false);
    final folderRepo = Provider.of<FolderRepository>(context, listen: false);

    final isEdit = widget.card != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Card' : 'Add Card'),
      ),
      body: FutureBuilder<List<Folder>>(
        future: folderRepo.getAllFolders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!;

          if (folders.isEmpty) {
            return const Center(
              child: Text('No folders available.'),
            );
          }

          _selectedFolderId ??= folders.first.id;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedSuit,
                    decoration: const InputDecoration(
                      labelText: 'Suit',
                      border: OutlineInputBorder(),
                    ),
                    items: suits
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSuit = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: _selectedFolderId,
                    decoration: const InputDecoration(
                      labelText: 'Folder',
                      border: OutlineInputBorder(),
                    ),
                    items: folders
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.folderName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedFolderId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _imageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final newCard = PlayingCard(
                        id: widget.card?.id,
                        cardName: _nameController.text.trim(),
                        suit: _selectedSuit!,
                        imageUrl: _imageController.text.trim(),
                        folderId: _selectedFolderId!,
                      );

                      if (isEdit) {
                        await cardRepo.updateCard(newCard);
                      } else {
                        await cardRepo.insertCard(newCard);
                      }

                      if (mounted) Navigator.pop(context, true);
                    },
                    child: Text(isEdit ? 'Save Changes' : 'Add Card'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
