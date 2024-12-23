import 'dart:ui';

// ignore: constant_identifier_names
const ASCII_SPACE_OFFSET = 32;

sealed class Command {}

class DrawCmd implements Command {
  final int char;
  final int x;
  final int y;
  final bool invert;

  DrawCmd({
    required this.char,
    required this.x,
    required this.y,
    required this.invert,
  });
}

class ClearCmd implements Command {
  const ClearCmd();
}

class ColourCmd implements Command {
  final int r; // Red component
  final int g; // Green component
  final int b; // Blue component

  ColourCmd({
    required this.r,
    required this.g,
    required this.b,
  });
}

class GridCell {
  final int _char;
  final Color color;
  final bool invert;

  // SPACE char instead of ascii 0
  String get char =>
      String.fromCharCode(_char != 0 ? _char : ASCII_SPACE_OFFSET);

  GridCell(this._char, this.color, this.invert);

  @override
  String toString() {
    return "[$char] [$color]";
  }
}
