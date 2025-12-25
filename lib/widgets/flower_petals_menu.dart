import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlowerPetalsMenu extends StatefulWidget {
  final Offset centerPosition;

  const FlowerPetalsMenu({
    super.key,
    required this.centerPosition,
  });

  static void show(BuildContext context, Offset centerPosition) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      barrierDismissible: true,
      builder: (context) => FlowerPetalsMenu(centerPosition: centerPosition),
    );
  }

  @override
  State<FlowerPetalsMenu> createState() => _FlowerPetalsMenuState();
}

class _FlowerPetalsMenuState extends State<FlowerPetalsMenu>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<AnimationController> _pressControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _opacityAnimations;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _pressScaleAnimations;
  int? _showingTooltipIndex; // Track which tooltip is currently showing

  final List<MenuButton> _menuItems = [
    MenuButton(
      icon: Icons.receipt_long_outlined,
      title: 'Transactions',
      color: const Color(0xFF27AE60),
      route: '/transactions',
    ),
    MenuButton(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Budget Planner',
      color: const Color(0xFFF39C12),
      route: '/budget-planner',
    ),
    MenuButton(
      icon: Icons.show_chart_outlined,
      title: 'Inflation Tracker',
      color: const Color(0xFFE74C3C),
      route: '/inflation-tracker',
    ),
    MenuButton(
      icon: Icons.trending_up_outlined,
      title: 'Predictions',
      color: const Color(0xFF5DADE2),
      route: '/predictions',
    ),
    MenuButton(
      icon: Icons.lightbulb_outline,
      title: 'Smart Suggestions',
      color: const Color(0xFF9B59B6),
      route: '/smart-suggestions',
    ),
    MenuButton(
      icon: Icons.analytics_outlined,
      title: 'Analytics & Reports',
      color: const Color(0xFF16A085),
      route: '/analytics-report',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _menuItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    
    _pressControllers = List.generate(
      _menuItems.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutBack,
        ),
      );
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();
    
    _pressScaleAnimations = _pressControllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    _slideAnimations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      // Half circle (180 degrees) on upper side
      // Start from left (-90°) to right (+90°), all in upper half
      // Map index to angle from 180° (left) to 0° (right)
      final angle = (180 - (index * 180 / (_menuItems.length - 1))) * (math.pi / 180);
      final radius = 120.0; // Increased spacing between buttons
      final endOffset = Offset(
        math.cos(angle) * radius,
        -math.sin(angle) * radius, // Negative to go upward
      );
      return Tween<Offset>(
        begin: Offset.zero,
        end: endOffset,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var controller in _pressControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _dismiss() {
    // Hide tooltip if showing
    if (_showingTooltipIndex != null) {
      setState(() {
        _showingTooltipIndex = null;
      });
    }
    // Reverse animations
    for (int i = _controllers.length - 1; i >= 0; i--) {
      Future.delayed(
        Duration(milliseconds: (_controllers.length - 1 - i) * 30),
        () {
          if (mounted) {
            _controllers[i].reverse();
          }
        },
      );
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleItemTap(MenuButton item) {
    // Close the menu first
    Navigator.of(context).pop();
    
    // Navigate to the dedicated screen after a short delay to allow menu to close
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      if (item.route == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} coming soon...'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (item.isReplace) {
        // For Dashboard, replace current route
        Navigator.of(context).pushReplacementNamed(item.route!);
      } else {
        // For other screens, push new route
        Navigator.of(context).pushNamed(item.route!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Detect taps on transparent areas
        onTap: _dismiss,
        child: SizedBox.expand(
          child: Stack(
            children: [
            // Layer 1: All Icon Buttons (rendered first, lower z-index)
            ..._menuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              // Half circle (180 degrees) on upper side
              // Start from left (-90°) to right (+90°), all in upper half
              final angle = (180 - (index * 180 / (_menuItems.length - 1))) * (math.pi / 180);
              final radius = 120.0; // Increased spacing between buttons

              return AnimatedBuilder(
                animation: Listenable.merge([_controllers[index], _pressControllers[index]]),
                builder: (context, child) {
                  final scale = _scaleAnimations[index].value;
                  final opacity = _opacityAnimations[index].value;
                  final slide = _slideAnimations[index].value;
                  final pressScale = _pressScaleAnimations[index].value;

                  // Calculate icon center position
                  final iconCenterX = widget.centerPosition.dx + slide.dx;
                  final iconCenterY = widget.centerPosition.dy + slide.dy;
                  final isShowingTooltip = _showingTooltipIndex == index;
                  
                  return Positioned(
                    left: iconCenterX - 28,
                    top: iconCenterY - 28,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale * pressScale,
                        child: GestureDetector(
                          behavior: HitTestBehavior.deferToChild,
                          onTapDown: (_) {
                            _pressControllers[index].forward();
                          },
                          onTapUp: (_) {
                            _pressControllers[index].reverse();
                            if (!isShowingTooltip) {
                              _handleItemTap(item);
                            }
                            // Hide tooltip on tap up
                            if (isShowingTooltip) {
                              setState(() {
                                _showingTooltipIndex = null;
                              });
                            }
                          },
                          onTapCancel: () {
                            _pressControllers[index].reverse();
                            if (isShowingTooltip) {
                              setState(() {
                                _showingTooltipIndex = null;
                              });
                            }
                          },
                          onLongPress: () {
                            // Show tooltip on long press
                            setState(() {
                              _showingTooltipIndex = index;
                            });
                          },
                          onLongPressEnd: (_) {
                            // Keep tooltip visible until tap
                            // Tooltip will be dismissed on tap up
                          },
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: item.color.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              item.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            // Layer 2: All Tooltips (rendered last, highest z-index - always on top)
            ..._menuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final angle = (180 - (index * 180 / (_menuItems.length - 1))) * (math.pi / 180);
              final isShowingTooltip = _showingTooltipIndex == index;
              
              if (!isShowingTooltip) return const SizedBox.shrink();
              
              return AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, child) {
                  final slide = _slideAnimations[index].value;
                  final opacity = _opacityAnimations[index].value;
                  
                  // Calculate icon center position for tooltip placement
                  final iconCenterX = widget.centerPosition.dx + slide.dx;
                  final iconCenterY = widget.centerPosition.dy + slide.dy;
                  
                  return Positioned(
                    left: iconCenterX - 60,
                    top: iconCenterY - 70,
                    width: 120,
                    child: Opacity(
                      opacity: opacity,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.color.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: item.color.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.color,
                              letterSpacing: 0.3,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuButton {
  final IconData icon;
  final String title;
  final Color color;
  final String? route;
  final bool isReplace;

  MenuButton({
    required this.icon,
    required this.title,
    required this.color,
    this.route,
    this.isReplace = false,
  });
}

