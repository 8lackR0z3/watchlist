import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bookmark.dart';
import '../services/database_service.dart';
import '../widgets/parallax_card.dart';
import '../widgets/bookmark_edit_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  
  List<Bookmark> _bookmarks = [];
  Category? _selectedCategory;
  bool _isLoading = true;
  String _searchQuery = '';

  final List<Category?> _tabs = [null, ...Category.values];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookmarks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedCategory = _tabs[_tabController.index];
    });
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    
    try {
      final bookmarks = await _db.readAll(category: _selectedCategory);
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load bookmarks');
    }
  }

  Future<void> _addBookmark(Bookmark bookmark) async {
    try {
      await _db.create(bookmark);
      _loadBookmarks();
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to add bookmark');
    }
  }

  Future<void> _updateBookmark(Bookmark bookmark) async {
    try {
      await _db.update(bookmark);
      _loadBookmarks();
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to update bookmark');
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Bookmark?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${bookmark.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && bookmark.id != null) {
      try {
        await _db.delete(bookmark.id!);
        _loadBookmarks();
        HapticFeedback.mediumImpact();
      } catch (e) {
        _showError('Failed to delete bookmark');
      }
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open URL');
      }
    } catch (e) {
      _showError('Invalid URL');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkEditSheet(
        onSave: _addBookmark,
      ),
    );
  }

  void _showEditSheet(Bookmark bookmark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookmarkEditSheet(
        bookmark: bookmark,
        onSave: _updateBookmark,
      ),
    );
  }

  List<Bookmark> get _filteredBookmarks {
    if (_searchQuery.isEmpty) return _bookmarks;
    return _bookmarks.where((b) =>
        b.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    )
                  : _filteredBookmarks.isEmpty
                      ? _buildEmptyState()
                      : _buildGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'WatchList',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: BookmarkSearchDelegate(
                      bookmarks: _bookmarks,
                      onTap: _openUrl,
                      onEdit: _showEditSheet,
                      onDelete: _deleteBookmark,
                    ),
                  );
                },
              ),
            ],
          ),
          Text(
            '${_bookmarks.length} bookmarks',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: Colors.purple,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: _tabs.map((category) {
          if (category == null) {
            return const Tab(text: 'All');
          }
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.emoji),
                const SizedBox(width: 6),
                Text(category.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCategory?.emoji != null
                ? Icons.bookmark_border
                : Icons.collections_bookmark_outlined,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory != null
                ? 'No ${_selectedCategory!.label.toLowerCase()} bookmarks yet'
                : 'No bookmarks yet',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first bookmark',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadBookmarks,
      color: Colors.purple,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 160 / 220,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _filteredBookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = _filteredBookmarks[index];
          return ParallaxCard(
            bookmark: bookmark,
            onTap: () => _openUrl(bookmark.url),
            onLongPress: () => _showCardOptions(bookmark),
          );
        },
      ),
    );
  }

  void _showCardOptions(Bookmark bookmark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    bookmark.category.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bookmark.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.open_in_browser, color: Colors.white70),
              title: const Text('Open URL', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openUrl(bookmark.url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white70),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditSheet(bookmark);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _deleteBookmark(bookmark);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Search delegate for searching bookmarks
class BookmarkSearchDelegate extends SearchDelegate<Bookmark?> {
  final List<Bookmark> bookmarks;
  final Function(String) onTap;
  final Function(Bookmark) onEdit;
  final Function(Bookmark) onDelete;

  BookmarkSearchDelegate({
    required this.bookmarks,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  String get searchFieldLabel => 'Search bookmarks...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white38),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    final results = bookmarks.where((b) =>
        b.title.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Container(
      color: const Color(0xFF121212),
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final bookmark = results[index];
          return ListTile(
            leading: Text(
              bookmark.category.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              bookmark.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              bookmark.progressText.isEmpty
                  ? bookmark.category.label
                  : '${bookmark.category.label} • ${bookmark.progressText}',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () {
              close(context, bookmark);
              onTap(bookmark.url);
            },
          );
        },
      ),
    );
  }
}
