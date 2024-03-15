// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:picotracker_client/main.dart';
import 'package:picotracker_client/widgets/screen_char_row.dart';

class PicoScreen extends StatelessWidget {
  final ScreenCharGrid grid;
  final Color backgroundColor;

  const PicoScreen(this.grid, this.backgroundColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: grid
            .getRows()
            .map((row) => ScreenCharRow(
                  row,
                  grid,
                ))
            .toList(),
      ),
    );
  }
}
