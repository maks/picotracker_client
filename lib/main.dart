// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() {
  runApp(const MyApp());
  try {
    SerialPort('/dev/ttyACM0').close();
  } catch (e) {
    print("could not close serial port $e");
  }
}

const ASCII_SPACE = 32;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'picoTracker',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: "VT323"),
      home: const MyHomePage(title: 'picoTracker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
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

class _MyHomePageState extends State<MyHomePage> {
  var availablePorts = <String>[];
  int keymask = 0;
  StreamSubscription? subscription;
  StreamSubscription? cmdStreamSubscription;
  SerialPort? port;
  final _grid = ScreenCharGrid();
  final cmdBuilder = CmdBuilder();

  void _sendCmd(int c) {
    List<int> data = [c];
    Uint8List bytes = Uint8List.fromList(data);
    print(port!.write(bytes));
  }

  @override
  void initState() {
    super.initState();
    initPorts();

    cmdBuilder.commands.listen((cmd) {
      setState(() {
        switch (cmd) {
          case DrawCmd():
            _grid.setChar((x: cmd.x, y: cmd.y), cmd.char, cmd.invert);
            break;
          case ClearCmd():
            _grid.clear();
            break;
          case ColourCmd():
            _grid.setColor(cmd.colour);
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
    cmdStreamSubscription?.cancel();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
    try {
      port = SerialPort('/dev/ttyACM0');
      port!.openRead();
      _listenPort();
    } catch (_) {
      print("NO Picotracker connected!");
    }
  }

  Future<void> _listenPort() async {
    SerialPortReader reader = SerialPortReader(port!, timeout: 10000);

    subscription = reader.stream.listen((data) {
      //print('received:$data');
      final byteBuf = data.buffer.asByteData();
      for (int i = 0; i < byteBuf.lengthInBytes; i++) {
        cmdBuilder.addByte(byteBuf.getUint8(i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          // just keyDown
          print("DOWN:[${event.logicalKey.keyId}]" + event.logicalKey.keyLabel);
          if (event.logicalKey.keyId == 4294968068) {
            keymask = keymask | KEY_UP;
          }
          if (event.logicalKey.keyId == 4294968065) {
            keymask = keymask | KEY_DOWN;
          }
          if (event.logicalKey.keyId == 4294968066) {
            keymask = keymask | KEY_LEFT;
          }
          if (event.logicalKey.keyId == 4294968067) {
            keymask = keymask | KEY_RIGHT;
          }
          if (event.logicalKey.keyId == 8589934850) {
            keymask = keymask | KEY_L;
          }
          print("down keymask:$keymask");
        }
        if (event is KeyUpEvent) {
          //print("UP:" + event.logicalKey.keyLabel);
          if (event.logicalKey.keyId == 4294968068) {
            keymask = keymask ^ KEY_UP;
          }
          if (event.logicalKey.keyId == 4294968065) {
            keymask = keymask ^ KEY_DOWN;
          }
          if (event.logicalKey.keyId == 4294968066) {
            keymask = keymask ^ KEY_LEFT;
          }
          if (event.logicalKey.keyId == 4294968067) {
            keymask = keymask ^ KEY_RIGHT;
          }
          if (event.logicalKey.keyId == 8589934850) {
            keymask = keymask ^ KEY_L;
          }
        }
        _sendCmd(keymask);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: PicoScreen(
          _grid,
          _grid.background,
        ),
      ),
    );
  }
}

const COLS = 32;
const ROWS = 24;

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

class ScreenCharRow extends StatelessWidget {
  final List<GridCell> rowChars;
  final ScreenCharGrid grid;

  const ScreenCharRow(this.rowChars, this.grid, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: rowChars
          .map((cell) => Text(
                cell.char,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      height: 0.75,
                      letterSpacing: 4,
                      fontSize: 32,
                      color: cell.invert ? grid.background : cell.color,
                      backgroundColor:
                          cell.invert ? cell.color : Colors.transparent,
                    ),
              ))
          .toList(),
    );
  }
}

enum CommandType {
  DRAW(4),
  CLEAR(1),
  COLOUR(1);

  const CommandType(this.paramCount);
  final int paramCount;
}

class CmdBuilder {
  CommandType? _type;
  final List<int> _byteBuffer = [];
  bool cmdStarted = false;
  final _commandStreamController = StreamController<Command>.broadcast();

  Stream<Command> get commands => _commandStreamController.stream;

  void addByte(int byte) {
    if (byte == 0xFD) {
      if (cmdStarted) {
        //print("INCOMPLETE CMD:[$_type] $_byteBuffer");
      }
      _reset();
      cmdStarted = true;
    } else if (_type == null && cmdStarted) {
      switch (byte) {
        case 0x01:
          _type = CommandType.DRAW;
          break;
        case 0x02:
          _type = CommandType.CLEAR;
          break;
        case 0x03:
          _type = CommandType.COLOUR;
          break;
        default:
          print("INVALID COMMAND TYPE!!!!! [$byte]");
      }
    } else if (byte == 0xFE) {
      _build();
    } else {
      if (cmdStarted) {
        _byteBuffer.add(byte);
      }
    }
  }

  // build command if we have all the bytes for it
  void _build() {
    switch (_type) {
      case CommandType.DRAW:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = DrawCmd(
            char: _byteBuffer[0],
            // x & y co-ords are 1 indexed to avoid sending null chars in the serial data
            x: _byteBuffer[1] - 32,
            y: _byteBuffer[2] - 32,
            invert: _byteBuffer[3] == 127,
          );
          _reset();
          if (cmd.x > 31 || cmd.y > 23) {
            print("BAD DRAW DATA:${cmd.x} ${cmd.y} [${cmd.char}]");
          } else {
            _commandStreamController.add(cmd);
          }
        }
        break;
      case CommandType.CLEAR:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = ClearCmd(colour: _byteBuffer[0] - 1);
          _commandStreamController.add(cmd);
          _reset();
        }
        break;
      case CommandType.COLOUR:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = ColourCmd(colour: _byteBuffer[0] - 1);
          _commandStreamController.add(cmd);
          _reset();
        }
        break;
      case null:
        break;
    }
  }

  void _reset() {
    _byteBuffer.clear();
    _type = null;
    cmdStarted = false;
  }
}

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
