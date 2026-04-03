import 'package:flutter/material.dart';

class AnimatedBottomNavigationBar extends StatefulWidget {
  final List<IconData> icons;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;
  final double gapLocation;
  final double notchMargin;
  final double leftCornerRadius;
  final double rightCornerRadius;
  final Function(int) onTap;

  const AnimatedBottomNavigationBar({
    super.key,
    required this.icons,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.gapLocation = 0.0,
    this.notchMargin = 8.0,
    this.leftCornerRadius = 32.0,
    this.rightCornerRadius = 32.0,
  });

  @override
  State<AnimatedBottomNavigationBar> createState() => _AnimatedBottomNavigationBarState();
}

class _AnimatedBottomNavigationBarState extends State<AnimatedBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      notchMargin: widget.notchMargin,
      shape: CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.icons.asMap().entries.map((entry) {
          final index = entry.key;
          final icon = entry.value;
          final isActive = index == widget.activeIndex;
          
          return GestureDetector(
            onTap: () => widget.onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? widget.activeColor : widget.inactiveColor,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    width: isActive ? 20 : 0,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}