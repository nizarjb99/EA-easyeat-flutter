import 'package:flutter/material.dart';
import 'accessibility_panel.dart';

class AccessibilityFloatingButton extends StatefulWidget {
  const AccessibilityFloatingButton({super.key});

  @override
  State<AccessibilityFloatingButton> createState() =>
      _AccessibilityFloatingButtonState();
}

class _AccessibilityFloatingButtonState
    extends State<AccessibilityFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _animCtrl;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _animCtrl.reverse();
    await _animCtrl.forward();
    if (mounted) {
      showAccessibilityPanel(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2979FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2979FF).withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.accessibility_new_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
