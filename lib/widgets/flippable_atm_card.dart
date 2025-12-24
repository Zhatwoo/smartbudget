import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlippableAtmCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double? width;
  final double? height;
  final ValueChanged<bool>? onFlipChanged;

  const FlippableAtmCard({
    super.key,
    required this.front,
    required this.back,
    this.width,
    this.height,
    this.onFlipChanged,
  });

  @override
  State<FlippableAtmCard> createState() => _FlippableAtmCardState();
}

class _FlippableAtmCardState extends State<FlippableAtmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    
    final wasFront = _isFront;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
    // Notify after state change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onFlipChanged?.call(_isFront);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) return;
    
    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_controller.isAnimating) return;
    
    const threshold = 50.0;
    if (_dragOffset.abs() > threshold) {
      if (_dragOffset < 0 && _isFront) {
        // Dragged left, flip to back
        _flip();
      } else if (_dragOffset > 0 && !_isFront) {
        // Dragged right, flip to front
        _flip();
      }
    }
    
    setState(() {
      _dragOffset = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? MediaQuery.of(context).size.width - 32;
    final cardHeight = widget.height ?? cardWidth / 1.5; // Slightly taller to accommodate content

    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final rotation = _animation.value * math.pi;
          final isBackVisible = rotation > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(rotation),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: isBackVisible
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: widget.back,
                    )
                  : widget.front,
            ),
          );
        },
      ),
    );
  }
}

