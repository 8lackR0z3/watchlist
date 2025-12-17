import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bookmark.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('watchlist.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        image_url TEXT,
        category TEXT NOT NULL,
        episode INTEGER,
        season INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Create index for faster category filtering
    await db.execute('''
      CREATE INDEX idx_category ON bookmarks(category)
    ''');
  }

  // CRUD Operations

  /// Insert a new bookmark
  Future<Bookmark> create(Bookmark bookmark) async {
    final db = await database;
    final id = await db.insert('bookmarks', bookmark.toMap());
    return bookmark.copyWith(id: id);
  }

  /// Get a bookmark by ID
  Future<Bookmark?> read(int id) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Bookmark.fromMap(maps.first);
    }
    return null;
  }

  /// Get all bookmarks, optionally filtered by category
  Future<List<Bookmark>> readAll({Category? category}) async {
    final db = await database;
    
    List<Map<String, dynamic>> maps;
    if (category != null) {
      maps = await db.query(
        'bookmarks',
        where: 'category = ?',
        whereArgs: [category.name],
        orderBy: 'updated_at DESC',
      );
    } else {
      maps = await db.query(
        'bookmarks',
        orderBy: 'updated_at DESC',
      );
    }

    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  /// Update an existing bookmark
  Future<int> update(Bookmark bookmark) async {
    final db = await database;
    return await db.update(
      'bookmarks',
      bookmark.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [bookmark.id],
    );
  }

  /// Delete a bookmark
  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all bookmarks
  Future<int> deleteAll() async {
    final db = await database;
    return await db.delete('bookmarks');
  }

  /// Get count of bookmarks by category
  Future<Map<Category, int>> getCategoryCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM bookmarks 
      GROUP BY category
    ''');

    final counts = <Category, int>{};
    for (final row in result) {
      final category = Category.fromString(row['category'] as String);
      counts[category] = row['count'] as int;
    }
    return counts;
  }

  /// Search bookmarks by title
  Future<List<Bookmark>> search(String query) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => Bookmark.fromMap(map)).toList();
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
