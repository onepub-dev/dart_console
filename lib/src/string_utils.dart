import 'package:characters/characters.dart';

import 'textalignment.dart';

extension StringUtils on String {
  /// Take an input string and wrap it across multiple lines.
  String wrapText([int wrapLength = 76]) {
    if (isEmpty) {
      return '';
    }

    final words = split(' ');
    final textLine = StringBuffer(words.first);
    final outputText = StringBuffer();

    for (final word in words.skip(1)) {
      if ((textLine.length + word.length) > wrapLength) {
        textLine.write('\n');
        outputText.write(textLine);
        textLine
          ..clear()
          ..write(word);
      } else {
        textLine.write(' $word');
      }
    }

    outputText.write(textLine);
    return outputText.toString().trimRight();
  }

  String alignText({
    required int width,
    TextAlignment alignment = TextAlignment.left,
  }) {
    // We can't use the padLeft() and padRight() methods here, since they
    // don't account for ANSI escape sequences.
    switch (alignment) {
      case TextAlignment.center:
        // By using ceil _and_ floor, we ensure that the target width is reached
        // even if the padding is uneven (e.g. a single character wrapped in a 4
        // character width should be wrapped as '··c·' rather than '··c··').
        final leftPadding = ' ' * ((width - displayWidth) / 2).ceil();
        final rightPadding = ' ' * ((width - displayWidth) / 2).floor();
        return leftPadding + this + rightPadding;
      case TextAlignment.right:
        final padding = ' ' * (width - displayWidth);
        return padding + this;
      case TextAlignment.left:
        final padding = ' ' * (width - displayWidth);
        return this + padding;
    }
  }

  String stripEscapeCharacters() {
    return replaceAll(RegExp(r'\x1b\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]'), '')
        .replaceAll(RegExp(r'\x1b[PX^_].*?\x1b\\'), '')
        .replaceAll(RegExp(r'\x1b\][^\a]*(?:\a|\x1b\\)'), '')
        .replaceAll(RegExp(r'\x1b[\[\]A-Z\\^_@]'), '');
  }

  /// The number of displayed character cells that are represented by the
  /// string.
  ///
  /// This should never be more than the length of the string; it excludes ANSI
  /// control characters.
  int get displayWidth => stripEscapeCharacters().length;

  /// Given a string of numerals, returns their superscripted form.
  ///
  /// If the string contains non-numeral characters, they are returned
  /// unchanged.
  String superscript() => _convertNumerals('⁰¹²³⁴⁵⁶⁷⁸⁹');

  /// Given a string of numerals, returns their subscripted form.
  ///
  /// If the string contains non-numeral characters, they are returned
  /// unchanged.
  String subscript() => _convertNumerals('₀₁₂₃₄₅₆₇₈₉');

  String _convertNumerals(String replacementNumerals) {
    const zeroCodeUnit = 0x30;
    const nineCodeUnit = 0x39;

    final buffer = StringBuffer();
    for (var c in characters) {
      final firstCodeUnit = c.codeUnits.first;
      if (c.codeUnits.length == 1 &&
          firstCodeUnit >= zeroCodeUnit &&
          firstCodeUnit <= nineCodeUnit) {
        buffer.write(replacementNumerals[firstCodeUnit - zeroCodeUnit]);
      } else {
        buffer.write(c);
      }
    }
    return buffer.toString();
  }

  /// Checks if a **single character** is a **full-width character** (occupies 2 columns).
  /// Authoritative standard: Unicode East Asian Width (EAW)
  bool isFullWidthCharacter() {
    if (isEmpty) return false;
    // Only handle single visual characters (avoid combining characters/corrupted text)
    if (characters.length != 1) return false;

    final code = runes.first;

    // 1. CJK Unified Ideographs (all Chinese characters)
    if (code >= 0x4E00 && code <= 0x9FFF) return true;
    // 2. Japanese Hiragana and Katakana
    if (code >= 0x3040 && code <= 0x30FF) return true;
    // 3. Korean Hangul Syllables
    if (code >= 0xAC00 && code <= 0xD7AF) return true;
    // 4. Full-width punctuation marks
    if (code >= 0x3000 && code <= 0x303F) return true;
    // 5. Full-width letters/digits/symbols (Ａ Ｂ Ｃ １２３！＠＃)
    if (code >= 0xFF00 && code <= 0xFFEF) return true;
    // 6. Emoji & special symbols (occupy 2 columns in terminal)
    if (code >= 0x1F600 && code <= 0x1F64F) return true; // Emoticons
    if (code >= 0x1F300 && code <= 0x1F5FF) return true; // Icons
    // 7. Full-width space (especially important)
    if (code == 0x3000) return true;

    return false;
  }

  /// Calculates the actual display width of a string in the **terminal**.
  /// (Solves cursor offset issues)
  int getDisplayWidth() {
    int width = 0;
    for (final char in characters) {
      width += char.isFullWidthCharacter() ? 2 : 1;
    }
    return width;
  }
}
