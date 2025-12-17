/// Category types for bookmarks
enum Category {
  anime('Anime', '🎬'),
  manga('Manga', '📖'),
  tv('TV', '📺'),
  movie('Movie', '🎥'),
  podcast('Podcast', '🎧');

  final String label;
  final String emoji;
  
  const Category(this.label, this.emoji);
  
  static Category fromString(String value) {
    return Category.values.firstWhere(
      (c) => c.name == value,
      orElse: () => Category.anime,
    );
  }
}

/// Bookmark model representing a saved media item
class Bookmark {
  final int? id;
  final String title;
  final String url;
  final String? imageUrl;
  final Category category;
  final int? episode;
  final int? season;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bookmark({
    this.id,
    required this.title,
    required this.url,
    this.imageUrl,
    required this.category,
    this.episode,
    this.season,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create from database map
  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      imageUrl: map['image_url'] as String?,
      category: Category.fromString(map['category'] as String),
      episode: map['episode'] as int?,
      season: map['season'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'url': url,
      'image_url': imageUrl,
      'category': category.name,
      'episode': episode,
      'season': season,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Bookmark copyWith({
    int? id,
    String? title,
    String? url,
    String? imageUrl,
    Category? category,
    int? episode,
    int? season,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      episode: episode ?? this.episode,
      season: season ?? this.season,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Display string for progress (e.g., "S1 E5" or "Ch 42")
  String get progressText {
    if (category == Category.manga) {
      return episode != null ? 'Ch $episode' : '';
    }
    if (season != null && episode != null) {
      return 'S$season E$episode';
    }
    if (episode != null) {
      return 'Ep $episode';
    }
    return '';
  }

  @override
  String toString() {
    return 'Bookmark(id: $id, title: $title, category: ${category.label}, progress: $progressText)';
  }
}
