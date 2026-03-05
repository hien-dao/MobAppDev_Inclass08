import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // IMPORTANT: required so ON DELETE CASCADE actually works
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
          ON DELETE CASCADE
      )
    ''');

    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  Future _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    for (int i = 0; i < folders.length; i++) {
      await db.insert('folders', {
        'folder_name': folders[i],
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    final cards = [
      'Ace','2','3','4','5','6','7','8','9','10','Jack','Queen','King'
    ];
    final suits_short = ['H', 'D', 'C', 'S'];
    final cards_short = [
      'A','2','3','4','5','6','7','8','9','10','J','Q','K'
    ];

    for (int folderId = 1; folderId <= suits.length; folderId++) {
      final suit = suits[folderId - 1];
      final suit_short = suits_short[folderId - 1];
      for (var card in cards) {
        final card_short = cards_short[cards.indexOf(card)];
        await db.insert('cards', {
          'card_name': card,
          'suit': suit,
          'image_url': 'https://deckofcardsapi.com/static/img/$card_short$suit_short.png',
          'folder_id': folderId,
        });
      }
    }
  }
}