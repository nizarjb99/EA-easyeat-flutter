import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'accessibility_controller.dart';

/// Wraps any screen content and applies accessibility overrides
/// (background color, text color, font scale, etc.) WITHOUT breaking
/// navigation bars, system icons, or the chat button.
///
/// Usage – wrap only the Scaffold body or the page-level widget:
///
/// ```dart
/// return AccessibilityWrapper(
///   child: Scaffold(
///     body: ...,
///   ),
/// );
/// ```
///
/// ⚠️  Do NOT wrap [MaterialApp] or [Scaffold.bottomNavigationBar] with this
/// widget – that would interfere with system-level widgets.
class AccessibilityWrapper extends StatelessWidget {
  const AccessibilityWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AccessibilityController>();

    return MediaQuery(
      // Apply fontScale without affecting system UI.
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(ctrl.fontScale),
      ),
      child: DefaultTextStyle.merge(
        // Apply text-level overrides. Icons and navigation are unaffected
        // because they use [IconTheme] and [NavigationBar], not DefaultTextStyle.
        style: TextStyle(
          color: ctrl.textColor,
          letterSpacing: ctrl.letterSpacing,
          height: ctrl.lineHeight,
          fontFamily: ctrl.fontFamilyName,
        ),
        child: ColoredBox(
          color: ctrl.bgColor,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

/// Safe image widget that respects the [hideImages] accessibility setting.
///
/// Use this instead of raw [Image.network] or [Image.asset] for
/// decorative / content images. Icons and navigation icons are unaffected.
///
/// Example:
/// ```dart
/// AccessibilityImage.network(
///   url: 'https://example.com/photo.jpg',
///   width: 200,
///   height: 120,
///   fit: BoxFit.cover,
/// )
/// ```
class AccessibilityImage extends StatelessWidget {
  const AccessibilityImage._({
    super.key,
    required this.imageWidget,
    this.width,
    this.height,
    this.fit,
    this.placeholderColor,
  });

  /// Network image that respects hide-images setting.
  factory AccessibilityImage.network({
    Key? key,
    required String url,
    double? width,
    double? height,
    BoxFit? fit,
    Color? placeholderColor,
  }) {
    return AccessibilityImage._(
      key: key,
      width: width,
      height: height,
      fit: fit,
      placeholderColor: placeholderColor,
      imageWidget: Image.network(
        url,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _placeholder(
          width: width,
          height: height,
          color: placeholderColor,
        ),
      ),
    );
  }

  /// Asset image that respects hide-images setting.
  factory AccessibilityImage.asset({
    Key? key,
    required String path,
    double? width,
    double? height,
    BoxFit? fit,
    Color? placeholderColor,
  }) {
    return AccessibilityImage._(
      key: key,
      width: width,
      height: height,
      fit: fit,
      placeholderColor: placeholderColor,
      imageWidget: Image.asset(
        path,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
      ),
    );
  }

  final Widget imageWidget;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? placeholderColor;

  static Widget _placeholder({double? width, double? height, Color? color}) {
    return Container(
      width: width,
      height: height,
      color: color ?? const Color(0xFFE0E0E0),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white54, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AccessibilityController>();

    if (ctrl.hideImages) {
      return _placeholder(
        width: width,
        height: height,
        color: placeholderColor,
      );
    }

    return imageWidget;
  }
}
