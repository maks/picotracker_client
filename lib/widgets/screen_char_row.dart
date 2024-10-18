// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:picotracker_client/picotracker/screen_char_grid.dart';

import '../commands.dart';

class ScreenCharRow extends StatelessWidget {
  final List<GridCell> rowChars;
  final ScreenCharGrid grid;

  const ScreenCharRow(this.rowChars, this.grid, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: rowChars
          .map((cell) => Text(
                cell.char == " " ? "  " : cell.char,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      height: 1.1,
                      letterSpacing: 1.2,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: cell.invert ? grid.background : cell.color,
                      backgroundColor:
                          cell.invert ? cell.color : Colors.transparent,
                    ),
              ))
          .toList(),
    );
  }
}
