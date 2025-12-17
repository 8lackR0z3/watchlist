import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/bookmark.dart';

class ParallaxCard extends StatefulWidget {
  final Bookmark bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFlip;
  
  const ParallaxCard({
    super.key,
    required this.bookmark,
    this.onTap,
    this.onLongPress,
    this.onFlip,
  });

  @override
  State<ParallaxCard> createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard>
    with TickerProviderStateMixin {
  // Tilt values (-1 to 1)
  double _tiltX = 0;
  double _tiltY = 0;
  
  // Animation controllers
  late AnimationController _returnController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  bool _isFlipped = false;
  bool _isDragging = false;

  // Card dimensions
  static const double _cardWidth = 160;
  static const double _cardHeight = 220;
  static const double _maxTiltAngle = 15; // degrees
  static const double _parallaxIntensity = 20; // pixels

  @override
  void initState() {
    super.initState();
    
    _returnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _returnController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _returnController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (!_isDragging) return;
    
    setState(() {
      // Calculate tilt based on drag delta
      _tiltX += details.delta.dx / size.width * 2;
      _tiltY -= details.delta.dy / size.height * 2;
      
      // Clamp values
      _tiltX = _tiltX.clamp(-1.0, 1.0);
      _tiltY = _tiltY.clamp(-1.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    _animateReturn();
  }

  void _animateReturn() {
    final startX = _tiltX;
    final startY = _tiltY;
    
    _returnController.reset();
    _returnController.forward();
    
    _returnController.addListener(() {
      if (mounted) {
        final t = Curves.easeOutCubic.transform(_returnController.value);
        setState(() {
          _tiltX = startX * (1 - t);
          _tiltY = startY * (1 - t);
        });
      }
    });
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
    
    if (_isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: (details) => _onPanUpdate(details, const Size(_cardWidth, _cardHeight)),
      onPanEnd: _onPanEnd,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onDoubleTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final flipValue = _flipAnimation.value;
          final isShowingBack = flipValue > 0.5;
          
          return Transform(
            alignment: Alignment.center,
            transform: _buildTransform(flipValue),
            child: isShowingBack
                ? _buildBackFace()
                : _buildFrontFace(),
          );
        },
      ),
    );
  }

  Matrix4 _buildTransform(double flipValue) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateY(_tiltX * _maxTiltAngle * math.pi / 180)
      ..rotateX(_tiltY * _maxTiltAngle * math.pi / 180)
      ..rotateY(flipValue * math.pi); // Flip animation
    
    return matrix;
  }

  Widget _buildFrontFace() {
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3 + (_tiltX.abs() + _tiltY.abs()) * 0.1),
            blurRadius: 20 + (_tiltX.abs() + _tiltY.abs()) * 10,
            offset: Offset(
              _tiltX * 10,
              10 + _tiltY * 5,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Parallax background image
            _buildParallaxImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            
            // Content
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(widget.bookmark.category).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.bookmark.category.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Title
                  Text(
                    widget.bookmark.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Progress
                  if (widget.bookmark.progressText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.bookmark.progressText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Shine effect on tilt
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment(
                      -1 + _tiltX * 2,
                      -1 + _tiltY * 2,
                    ),
                    end: Alignment(
                      1 + _tiltX * 2,
                      1 + _tiltY * 2,
                    ),
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.1 * (_tiltX.abs() + _tiltY.abs())),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxImage() {
    final offsetX = -_tiltX * _parallaxIntensity;
    final offsetY = _tiltY * _parallaxIntensity;
    
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.scale(
        scale: 1.1, // Slightly larger to allow parallax movement
        child: widget.bookmark.imageUrl != null && widget.bookmark.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.bookmark.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _getCategoryColor(widget.bookmark.category).withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _getCategoryColor(widget.bookmark.category).withOpacity(0.3),
      child: Center(
        child: Text(
          widget.bookmark.category.emoji,
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  Widget _buildBackFace() {
    // Flip the content so it's readable
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF2D2D2D),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    widget.bookmark.category.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.bookmark.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              
              // URL preview
              Text(
                'URL',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.bookmark.url,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Progress info
              if (widget.bookmark.progressText.isNotEmpty) ...[
                Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.bookmark.progressText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Hint text
              Center(
                child: Text(
                  'Double tap to flip back',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
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
