import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bookmark.dart';

class BookmarkEditSheet extends StatefulWidget {
  final Bookmark? bookmark;
  final Function(Bookmark) onSave;

  const BookmarkEditSheet({
    super.key,
    this.bookmark,
    required this.onSave,
  });

  @override
  State<BookmarkEditSheet> createState() => _BookmarkEditSheetState();
}

class _BookmarkEditSheetState extends State<BookmarkEditSheet> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _imageUrlController;
  late TextEditingController _episodeController;
  late TextEditingController _seasonController;
  late Category _selectedCategory;
  
  bool _isLoading = false;
  String? _imagePreviewError;

  @override
  void initState() {
    super.initState();
    final bookmark = widget.bookmark;
    
    _titleController = TextEditingController(text: bookmark?.title ?? '');
    _urlController = TextEditingController(text: bookmark?.url ?? '');
    _imageUrlController = TextEditingController(text: bookmark?.imageUrl ?? '');
    _episodeController = TextEditingController(
      text: bookmark?.episode?.toString() ?? '',
    );
    _seasonController = TextEditingController(
      text: bookmark?.season?.toString() ?? '',
    );
    _selectedCategory = bookmark?.category ?? Category.anime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _imageUrlController.dispose();
    _episodeController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.bookmark != null;

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }
    
    if (_urlController.text.trim().isEmpty) {
      _showError('Please enter a URL');
      return;
    }

    final bookmark = Bookmark(
      id: widget.bookmark?.id,
      title: _titleController.text.trim(),
      url: _urlController.text.trim(),
      imageUrl: _imageUrlController.text.trim().isEmpty 
          ? null 
          : _imageUrlController.text.trim(),
      category: _selectedCategory,
      episode: int.tryParse(_episodeController.text),
      season: int.tryParse(_seasonController.text),
      createdAt: widget.bookmark?.createdAt,
    );

    widget.onSave(bookmark);
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Header
            Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit : Icons.add_circle_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'Edit Bookmark' : 'Add Bookmark',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Category selector
            const Text(
              'Category',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 20),

            // Title field
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g., One Piece',
              icon: Icons.title,
            ),
            const SizedBox(height: 16),

            // URL field
            _buildTextField(
              controller: _urlController,
              label: 'URL',
              hint: 'https://...',
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Image URL field
            _buildTextField(
              controller: _imageUrlController,
              label: 'Cover Image URL (optional)',
              hint: 'https://...image.jpg',
              icon: Icons.image,
              keyboardType: TextInputType.url,
              onChanged: (value) {
                setState(() {
                  _imagePreviewError = null;
                });
              },
            ),
            
            // Image preview
            if (_imageUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImagePreview(),
            ],
            const SizedBox(height: 16),

            // Progress section
            Row(
              children: [
                if (_selectedCategory != Category.manga) ...[
                  Expanded(
                    child: _buildTextField(
                      controller: _seasonController,
                      label: 'Season',
                      hint: '1',
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _buildTextField(
                    controller: _episodeController,
                    label: _selectedCategory == Category.manga ? 'Chapter' : 'Episode',
                    hint: '1',
                    icon: Icons.bookmark_border,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(_selectedCategory),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Bookmark',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Category.values.map((category) {
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _getCategoryColor(category)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _getCategoryColor(category)
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getCategoryColor(_selectedCategory),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        _imageUrlController.text,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.white54,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white38, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Could not load image',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(Category category) {
    switch (category) {
      case Category.anime:
        return Colors.purple;
      case Category.manga:
        return Colors.orange;
      case Category.tv:
        return Colors.blue;
      case Category.movie:
        return Colors.red;
      case Category.podcast:
        return Colors.green;
    }
  }
}
