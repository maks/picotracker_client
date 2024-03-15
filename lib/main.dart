// ignore_for_file: constant_identifier_names, non_constant_identifier_names


import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:picotracker_client/pico_app.dart';

import 'commands.dart';

const COLS = 32;
const ROWS = 24;

void main() {
  runApp(const PicoApp());
  try {
    SerialPort('/dev/ttyACM0').close();
  } catch (e) {
    // ignore: avoid_print
    print("could not close serial port $e");
  }
}

final KEY_LEFT = int.parse("1", radix: 2);
final KEY_DOWN = int.parse("10", radix: 2);
final KEY_RIGHT = int.parse("100", radix: 2);
final KEY_UP = int.parse("1000", radix: 2);
final KEY_L = int.parse("10000", radix: 2);

typedef Coord = ({int x, int y});

class ScreenCharGrid {
  
  Color _currentColour = Colors.white;
  Color _backgroundColor = Colors.black;
  List<GridCell> _gridlist =
      List.filled(COLS * ROWS, GridCell(0, Colors.black, false));

  final List<Color> colorPalette = [
    const Color(0xFF000000),
    const Color(0xFF0049E5),
    const Color(0xFF00B926),
    const Color(0xFF00E371),
    const Color(0xFF009CF3),
    const Color(0xFF00A324),
    const Color(0xFF00EC46),
    const Color(0xFF00F70D),
    const Color(0xFF00ffff),
    const Color(0xFF001926),
    const Color(0xFF002A49),
    const Color(0xFF004443),
    const Color(0xFF00A664),
    const Color(0xFF0002B0),
    const Color(0xFF00351E),
    const Color(0xFF00B6FD)
  ];

  Color get color => _currentColour;

  Color get background => _backgroundColor;

  void setChar(Coord pos, int char, bool invert) {
    final int offset = (pos.y * COLS) + pos.x;
    final nuCell = GridCell(char, _currentColour, invert);
    _gridlist[offset] = nuCell;
  }

  void clear() {
    _gridlist = List.filled(COLS * ROWS, GridCell(0, _backgroundColor, false));
  }

  void setColor(int c) {
    // ignore: avoid_print
    print("setcolor:$c");
    _currentColour = colorPalette[c];
  }

  void setBackground(int c) {
    _backgroundColor = Color(c);
  }


  List<List<GridCell>> getRows() {
    var currentRow = <GridCell>[];
    final rows = List<List<GridCell>>.empty(growable: true);
    // split into rows
    for (int i = 0; i < _gridlist.length; i++) {
      currentRow.add(_gridlist[i]);
      if ((i + 1) % COLS == 0) {
        rows.add(currentRow);
        // print("ROW[$currentRow]\n");
        currentRow = [];
      }
    }
    return rows;
  }
}
