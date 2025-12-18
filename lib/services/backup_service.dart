import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/bookmark.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  final DatabaseService _db = DatabaseService.instance;

  BackupService._init();

  /// Export all bookmarks to JSON and share
  Future<bool> exportBookmarks() async {
    try {
      // Get all bookmarks
      final bookmarks = await _db.readAll();
      
      if (bookmarks.isEmpty) {
        return false;
      }

      // Convert to JSON
      final data = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'app': 'TheList',
        'count': bookmarks.length,
        'bookmarks': bookmarks.map((b) => {
          'title': b.title,
          'url': b.url,
          'image_url': b.imageUrl,
          'category': b.category.name,
          'episode': b.episode,
          'season': b.season,
          'created_at': b.createdAt.toIso8601String(),
          'updated_at': b.updatedAt.toIso8601String(),
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/thelist_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'TheList Backup',
        text: 'My TheList bookmarks backup (${bookmarks.length} items)',
      );

      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  /// Import bookmarks from a JSON file
  Future<ImportResult> importBookmarks() async {
    try {
      // Pick a JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: 'No file selected');
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate format
      if (!data.containsKey('bookmarks')) {
        return ImportResult(success: false, message: 'Invalid backup file format');
      }

      final bookmarksList = data['bookmarks'] as List<dynamic>;
      int imported = 0;
      int skipped = 0;

      for (final item in bookmarksList) {
        try {
          final bookmark = Bookmark(
            title: item['title'] as String,
            url: item['url'] as String,
            imageUrl: item['image_url'] as String?,
            category: Category.fromString(item['category'] as String),
            episode: item['episode'] as int?,
            season: item['season'] as int?,
            createdAt: DateTime.tryParse(item['created_at'] ?? ''),
            updatedAt: DateTime.tryParse(item['updated_at'] ?? ''),
          );

          // Check if bookmark with same URL already exists
          final existing = await _db.search(bookmark.url);
          if (existing.any((b) => b.url == bookmark.url)) {
            skipped++;
            continue;
          }

          await _db.create(bookmark);
          imported++;
        } catch (e) {
          skipped++;
        }
      }

      return ImportResult(
        success: true,
        message: 'Imported $imported bookmarks' + (skipped > 0 ? ' ($skipped skipped)' : ''),
        importedCount: imported,
        skippedCount: skipped,
      );
    } catch (e) {
      print('Import error: $e');
      return ImportResult(success: false, message: 'Error reading file: $e');
    }
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int skippedCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.skippedCount = 0,
  });
}
