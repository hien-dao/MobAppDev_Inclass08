import 'dart:core';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import '../database_helper.dart';
import '../models/card.dart';
import '../models/folder.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE - Insert a new folder
  Future insertFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.insert('folders', folder.toMap());
  }

  // READ - Get all folders
  Future<List<Folder>> getAllFolders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('folders');
    
    return List.generate(maps.length, (i) {
      return Folder.fromMap(maps[i]);
    });
  }

  // READ - Get a single folder by ID
  Future<Folder?> getFolderById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Folder.fromMap(maps.first);
  }

  // UPDATE - Update an existing folder
  Future updateFolder(Folder folder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  // DELETE - Delete a folder and all associated cards
  Future deleteFolder(int id) async {
    final db = await _dbHelper.database;
    // Due to ON DELETE CASCADE, this will also delete all cards
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get folder count
  Future getFolderCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM folders');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}