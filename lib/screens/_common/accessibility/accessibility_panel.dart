import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'accessibility_controller.dart';

/// Shows the accessibility panel as a modal bottom sheet.
void showAccessibilityPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AccessibilityPanel(),
  );
}

class AccessibilityPanel extends StatelessWidget {
  const AccessibilityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1E2B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Header ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        color: Color(0xFF2979FF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Accessibility',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    // Reset all button
                    Consumer<AccessibilityController>(
                      builder: (context, ctrl, _) => TextButton.icon(
                        onPressed: ctrl.hasCustomSettings ? ctrl.resetAll : null,
                        icon: Icon(
                          Icons.restart_alt_rounded,
                          size: 16,
                          color: ctrl.hasCustomSettings
                              ? const Color(0xFF2979FF)
                              : Colors.white24,
                        ),
                        label: Text(
                          'Reset all',
                          style: TextStyle(
                            fontSize: 13,
                            color: ctrl.hasCustomSettings
                                ? const Color(0xFF2979FF)
                                : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // ── Body ───────────────────────────────────────────────────────
              Expanded(
                child: Consumer<AccessibilityController>(
                  builder: (context, ctrl, _) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      children: [
                        // 1. Background Color
                        _Section(
                          title: 'Background Color',
                          icon: Icons.format_color_fill_rounded,
                          onReset: () => ctrl.setBgColor(Colors.white),
                          child: _ColorPicker(
                            selected: ctrl.bgColor,
                            colors: const [
                              Colors.white,
                              Color(0xFFFFF9C4), // soft yellow
                              Color(0xFFE8F5E9), // soft green
                              Color(0xFFE3F2FD), // soft blue
                              Color(0xFFFCE4EC), // soft pink
                              Color(0xFF263238), // dark slate
                              Color(0xFF1A1A2E), // dark navy
                              Colors.black,
                            ],
                            onSelected: ctrl.setBgColor,
                          ),
                        ),
                        const _Divider(),

                        // 2. Text Color
                        _Section(
                          title: 'Text Color',
                          icon: Icons.format_color_text_rounded,
                          onReset: () => ctrl.setTextColor(Colors.black),
                          child: _ColorPicker(
                            selected: ctrl.textColor,
                            colors: const [
                              Colors.black,
                              Color(0xFF212121),
                              Color(0xFF37474F),
                              Colors.white,
                              Color(0xFFFFF9C4),
                              Color(0xFFFFCC02),
                              Color(0xFF1565C0),
                              Color(0xFF2E7D32),
                            ],
                            onSelected: ctrl.setTextColor,
                          ),
                        ),
                        const _Divider(),

                        // 3. Font Size
                        _Section(
                          title: 'Font Size',
                          icon: Icons.format_size_rounded,
                          onReset: () => ctrl.setFontScale(1.0),
                          trailingLabel:
                              '${(ctrl.fontScale * 100).round()}%',
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF2979FF),
                              thumbColor: const Color(0xFF2979FF),
                              inactiveTrackColor: Colors.white12,
                              overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: ctrl.fontScale,
                              min: 0.8,
                              max: 2.0,
                              divisions: 12,
                              onChanged: ctrl.setFontScale,
                            ),
                          ),
                        ),
                        const _Divider(),

                        // 4. Letter Spacing
                        _Section(
                          title: 'Letter Spacing',
                          icon: Icons.space_bar_rounded,
                          onReset: () => ctrl.setLetterSpacing(0.0),
                          trailingLabel:
                              '${ctrl.letterSpacing.toStringAsFixed(1)}px',
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF2979FF),
                              thumbColor: const Color(0xFF2979FF),
                              inactiveTrackColor: Colors.white12,
                              overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: ctrl.letterSpacing,
                              min: -1.0,
                              max: 8.0,
                              divisions: 18,
                              onChanged: ctrl.setLetterSpacing,
                            ),
                          ),
                        ),
                        const _Divider(),

                        // 5. Line Height
                        _Section(
                          title: 'Line Height',
                          icon: Icons.format_line_spacing_rounded,
                          onReset: () => ctrl.setLineHeight(1.2),
                          trailingLabel:
                              ctrl.lineHeight.toStringAsFixed(1),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF2979FF),
                              thumbColor: const Color(0xFF2979FF),
                              inactiveTrackColor: Colors.white12,
                              overlayColor: const Color(0xFF2979FF).withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: ctrl.lineHeight,
                              min: 1.0,
                              max: 3.0,
                              divisions: 20,
                              onChanged: ctrl.setLineHeight,
                            ),
                          ),
                        ),
                        const _Divider(),

                        // 6. Font Family
                        _Section(
                          title: 'Font Family',
                          icon: Icons.font_download_rounded,
                          onReset: () =>
                              ctrl.setFontFamily(AccessibilityFont.system),
                          child: Row(
                            children: AccessibilityFont.values.map((font) {
                              final label = _fontLabel(font);
                              final selected = ctrl.fontFamily == font;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: GestureDetector(
                                    onTap: () => ctrl.setFontFamily(font),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFF2979FF)
                                            : Colors.white10,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: selected
                                            ? Border.all(
                                                color: const Color(0xFF2979FF),
                                                width: 2)
                                            : null,
                                      ),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : Colors.white60,
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const _Divider(),

                        // 7. Hide Images
                        _Section(
                          title: 'Hide Images',
                          icon: Icons.hide_image_rounded,
                          onReset: () => ctrl.setHideImages(false),
                          child: Row(
                            children: [
                              const Text(
                                'Hide decorative images',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 13),
                              ),
                              const Spacer(),
                              Switch.adaptive(
                                value: ctrl.hideImages,
                                activeThumbColor: Colors.white,
                                activeTrackColor: const Color(0xFF2979FF),
                                onChanged: ctrl.setHideImages,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fontLabel(AccessibilityFont font) {
    switch (font) {
      case AccessibilityFont.system:
        return 'Sans\nSerif';
      case AccessibilityFont.serif:
        return 'Serif';
      case AccessibilityFont.dyslexic:
        return 'Dyslexic';
    }
  }
}

// ── Reusable section wrapper ─────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.trailingLabel,
    this.onReset,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? trailingLabel;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2979FF), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailingLabel != null) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: const TextStyle(
                      color: Color(0xFF2979FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (trailingLabel == null) const Spacer(),
              if (onReset != null)
                GestureDetector(
                  onTap: onReset,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.refresh_rounded,
                        color: Colors.white24, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Color picker row ─────────────────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.colors,
    required this.onSelected,
  });

  final Color selected;
  final List<Color> colors;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final isSelected = selected.toARGB32() == c.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2979FF)
                    : Colors.white24,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: c == Colors.white || c.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white,
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ── Thin divider ─────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Colors.white10, height: 24);
  }
}
