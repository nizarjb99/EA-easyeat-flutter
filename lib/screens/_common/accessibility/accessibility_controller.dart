import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used to persist accessibility settings in SharedPreferences.
class _PrefKeys {
  static const String bgColor = 'a11y_bg_color';
  static const String textColor = 'a11y_text_color';
  static const String fontScale = 'a11y_font_scale';
  static const String letterSpacing = 'a11y_letter_spacing';
  static const String lineHeight = 'a11y_line_height';
  static const String fontFamily = 'a11y_font_family';
  static const String hideImages = 'a11y_hide_images';
}

/// Accessibility font family options.
enum AccessibilityFont {
  system, // null → uses app default (Sans-Serif system font)
  serif, // 'serif' (Georgia / serif fallback)
  dyslexic, // 'OpenDyslexic' – add the font asset later if desired
}

/// Global accessibility controller.
/// Wrap your app with [ChangeNotifierProvider] to make it available everywhere.
class AccessibilityController extends ChangeNotifier {
  // ── Defaults ────────────────────────────────────────────────────────────────
  static const Color _defaultBgColor = Colors.white;
  static const Color _defaultTextColor = Colors.black;
  static const double _defaultFontScale = 1.0;
  static const double _defaultLetterSpacing = 0.0;
  static const double _defaultLineHeight = 1.2;
  static const AccessibilityFont _defaultFont = AccessibilityFont.system;
  static const bool _defaultHideImages = false;

  // ── State ────────────────────────────────────────────────────────────────────
  Color _bgColor = _defaultBgColor;
  Color _textColor = _defaultTextColor;
  double _fontScale = _defaultFontScale;
  double _letterSpacing = _defaultLetterSpacing;
  double _lineHeight = _defaultLineHeight;
  AccessibilityFont _fontFamily = _defaultFont;
  bool _hideImages = _defaultHideImages;

  // ── Getters ──────────────────────────────────────────────────────────────────
  Color get bgColor => _bgColor;
  Color get textColor => _textColor;
  double get fontScale => _fontScale;
  double get letterSpacing => _letterSpacing;
  double get lineHeight => _lineHeight;
  AccessibilityFont get fontFamily => _fontFamily;
  bool get hideImages => _hideImages;

  /// Returns whether any setting differs from default.
  bool get hasCustomSettings =>
      _bgColor != _defaultBgColor ||
      _textColor != _defaultTextColor ||
      _fontScale != _defaultFontScale ||
      _letterSpacing != _defaultLetterSpacing ||
      _lineHeight != _defaultLineHeight ||
      _fontFamily != _defaultFont ||
      _hideImages != _defaultHideImages;

  // ── Font family name (safe – never returns a missing font asset) ─────────────
  String? get fontFamilyName {
    switch (_fontFamily) {
      case AccessibilityFont.system:
        return null; // Flutter uses platform default (sans-serif)
      case AccessibilityFont.serif:
        // 'Georgia' exists on iOS/Android/macOS; ignored gracefully if absent.
        return 'Georgia';
      case AccessibilityFont.dyslexic:
        // Return null until you add 'OpenDyslexic' to pubspec.yaml assets.
        // Replace null with 'OpenDyslexic' after adding the font.
        return null;
    }
  }

  // ── TextStyle helper ─────────────────────────────────────────────────────────
  /// Builds a [TextStyle] that applies all current accessibility settings.
  /// Merge this on top of any existing style using [TextStyle.merge] or
  /// pass it directly as [defaultTextStyle] in a [DefaultTextStyle] widget.
  TextStyle buildTextStyle({TextStyle? base}) {
    final merged = (base ?? const TextStyle()).copyWith(
      color: _textColor,
      letterSpacing: _letterSpacing,
      height: _lineHeight,
      fontFamily: fontFamilyName,
    );
    return merged;
  }

  // ── Load from SharedPreferences ──────────────────────────────────────────────
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    _bgColor = Color(prefs.getInt(_PrefKeys.bgColor) ?? _defaultBgColor.toARGB32());
    _textColor =
        Color(prefs.getInt(_PrefKeys.textColor) ?? _defaultTextColor.toARGB32());
    _fontScale = prefs.getDouble(_PrefKeys.fontScale) ?? _defaultFontScale;
    _letterSpacing =
        prefs.getDouble(_PrefKeys.letterSpacing) ?? _defaultLetterSpacing;
    _lineHeight = prefs.getDouble(_PrefKeys.lineHeight) ?? _defaultLineHeight;
    _fontFamily = AccessibilityFont.values[
        prefs.getInt(_PrefKeys.fontFamily) ?? _defaultFont.index];
    _hideImages = prefs.getBool(_PrefKeys.hideImages) ?? _defaultHideImages;

    notifyListeners();
  }

  // ── Persist helper ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_PrefKeys.bgColor, _bgColor.toARGB32());
    await prefs.setInt(_PrefKeys.textColor, _textColor.toARGB32());
    await prefs.setDouble(_PrefKeys.fontScale, _fontScale);
    await prefs.setDouble(_PrefKeys.letterSpacing, _letterSpacing);
    await prefs.setDouble(_PrefKeys.lineHeight, _lineHeight);
    await prefs.setInt(_PrefKeys.fontFamily, _fontFamily.index);
    await prefs.setBool(_PrefKeys.hideImages, _hideImages);
  }

  // ── Setters ──────────────────────────────────────────────────────────────────
  void setBgColor(Color color) {
    _bgColor = color;
    notifyListeners();
    _save();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
    _save();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 2.0);
    notifyListeners();
    _save();
  }

  void setLetterSpacing(double spacing) {
    _letterSpacing = spacing.clamp(-1.0, 8.0);
    notifyListeners();
    _save();
  }

  void setLineHeight(double height) {
    _lineHeight = height.clamp(1.0, 3.0);
    notifyListeners();
    _save();
  }

  void setFontFamily(AccessibilityFont font) {
    _fontFamily = font;
    notifyListeners();
    _save();
  }

  void setHideImages(bool hide) {
    _hideImages = hide;
    notifyListeners();
    _save();
  }

  // ── Reset all ────────────────────────────────────────────────────────────────
  Future<void> resetAll() async {
    _bgColor = _defaultBgColor;
    _textColor = _defaultTextColor;
    _fontScale = _defaultFontScale;
    _letterSpacing = _defaultLetterSpacing;
    _lineHeight = _defaultLineHeight;
    _fontFamily = _defaultFont;
    _hideImages = _defaultHideImages;
    notifyListeners();
    await _save();
  }
}
