import 'dart:ui';

// ignore: constant_identifier_names
const ASCII_SPACE = 32;

sealed class Command {}

class DrawCmd implements Command {
  final int char;
  final int x;
  final int y;
  final bool invert;

  DrawCmd(
      {required this.char,
      required this.x,
      required this.y,
      required this.invert});
}

class ClearCmd implements Command {
  final int colour;

  ClearCmd({required this.colour});
}

class ColourCmd implements Command {
  final int colour;

  ColourCmd({required this.colour});
}

class GridCell {
  final int _char;
  final Color color;
  final bool invert;

  // SPACE char instead of ascii 0
  String get char => String.fromCharCode(_char != 0 ? _char : ASCII_SPACE);

  GridCell(this._char, this.color, this.invert);

  @override
  String toString() {
    return "[$char] [$color]";
  }
}
