import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'models/card.dart';

// Here we are using a global variable. You can use something like
// get_it in a production app.
final dbHelper = DatabaseHelper.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize the database
  await dbHelper.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const FoldersPage(),
    );
  }
}

/// --------------------------
/// FOLDERS SCREEN (required)
/// --------------------------
class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  int refreshKey = 0;
  void refresh() => setState(() => refreshKey++);

  Future<List<Map<String, dynamic>>> getFoldersWithCounts() async {
    final db = await dbHelper.database;
    return db.rawQuery('''
      SELECT f.id, f.folder_name, COUNT(c.id) AS card_count
      FROM folders f
      LEFT JOIN cards c ON c.folder_id = f.id
      GROUP BY f.id
      ORDER BY f.id ASC
    ''');
  }

  Future<void> deleteFolder(int folderId, String folderName) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Non-dismissible for safety
      builder: (_) => AlertDialog(
        title: Text('Delete $folderName?'),
        content: const Text(
          'Clear warning: Deleting this folder will also delete ALL cards inside it (CASCADE deletion).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final db = await dbHelper.database;
      await db.delete('folders', where: 'id = ?', whereArgs: [folderId]);

      refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  IconData suitIcon(String name) {
    switch (name.toLowerCase()) {
      case 'hearts':
        return Icons.favorite;
      case 'diamonds':
        return Icons.diamond;
      case 'clubs':
        return Icons.filter_vintage;
      case 'spades':
        return Icons.change_history;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Folders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(refreshKey),
        future: getFoldersWithCounts(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final rows = snap.data ?? [];
          if (rows.isEmpty) {
            return const Center(child: Text('No folders found'));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = rows[i];
              final id = r['id'] as int;
              final name = r['folder_name'] as String;
              final count = (r['card_count'] as int?) ?? 0;

              return ListTile(
                leading: Icon(suitIcon(name)),
                title: Text(name),
                subtitle: Text('$count cards'),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardsPage(folderId: id, folderName: name),
                    ),
                  );
                  refresh();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteFolder(id, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ------------------------
/// CARDS SCREEN (required)
/// ------------------------
class CardsPage extends StatefulWidget {
  final int folderId;
  final String folderName;

  const CardsPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  int refreshKey = 0;
  void refresh() => setState(() => refreshKey++);

  Future<List<PlayingCard>> getCards() async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [widget.folderId],
      orderBy: 'id ASC',
    );
    return rows.map((m) => PlayingCard.fromMap(m)).toList();
  }

  // We are not touching images yet -> always placeholder
  Widget buildImagePlaceholder() => const Icon(Icons.image, size: 42);

  Future<void> deleteCard(PlayingCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delete card?'),
        content: const Text('This will permanently delete this card.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final db = await dbHelper.database;
      await db.delete('cards', where: 'id = ?', whereArgs: [card.id]);

      refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folderName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditCardPage(
                folderId: widget.folderId,
                defaultSuit: widget.folderName,
              ),
            ),
          );
          refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PlayingCard>>(
        key: ValueKey(refreshKey),
        future: getCards(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final cards = snap.data ?? [];
          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this folder'));
          }

          return ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = cards[i];

              return ListTile(
                leading: buildImagePlaceholder(),
                title: Text(c.cardName),
                subtitle: Text(c.suit),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditCardPage(
                              folderId: widget.folderId,
                              defaultSuit: widget.folderName,
                              existing: c,
                            ),
                          ),
                        );
                        refresh();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteCard(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// --------------------------
/// ADD/EDIT SCREEN (required)
/// --------------------------
class AddEditCardPage extends StatefulWidget {
  final int folderId;
  final String defaultSuit;
  final PlayingCard? existing;

  const AddEditCardPage({
    super.key,
    required this.folderId,
    required this.defaultSuit,
    this.existing,
  });

  @override
  State<AddEditCardPage> createState() => _AddEditCardPageState();
}

class _AddEditCardPageState extends State<AddEditCardPage> {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  late String suit;

  @override
  void initState() {
    super.initState();
    suit = widget.defaultSuit;

    if (widget.existing != null) {
      nameCtrl.text = widget.existing!.cardName;
      suit = widget.existing!.suit;
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final card = PlayingCard(
      id: widget.existing?.id,
      cardName: nameCtrl.text.trim(),
      suit: suit,
      imageUrl: null, // not using images yet
      folderId: widget.folderId,
    );

    try {
      final db = await dbHelper.database;

      if (widget.existing == null) {
        await db.insert('cards', card.toMap());
      } else {
        await db.update(
          'cards',
          card.toMap(),
          where: 'id = ?',
          whereArgs: [card.id],
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Card' : 'Add Card')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Card name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Card name required'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: suit,
                items: const ['Hearts', 'Diamonds', 'Clubs', 'Spades']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => suit = v ?? suit),
                decoration: const InputDecoration(
                  labelText: 'Suit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: save,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}