// ignore_for_file: constant_identifier_names

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'picoTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
          fontFamily: "VT323"
      ),
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

class ScreenCharGrid {
  ByteData _charBytes = Uint8List(COLS * ROWS).buffer.asByteData();

  ByteData get data => _charBytes;

  int getChar(int x, int y) {
    return _charBytes.getUint8((y * COLS) + x);
  }

  void setChar(int x, int y, int char) {
    _charBytes.setUint8((y * COLS) + x, char);
  }

  void clear() {
    _charBytes = Uint8List(COLS * ROWS).buffer.asByteData();
  }

  List<String> getRows() {
    final sb = StringBuffer();
    final rows = List<String>.empty(growable: true);
    for (int i = 0; i < _charBytes.lengthInBytes; i++) {
      int c = _charBytes.getUint8(i);
      sb.writeCharCode(c != 0 ? c : 32); // SPACE char in ascii 0
      if (i % COLS == 0) {
        rows.add(sb.toString());
        print(sb);
        sb.clear();
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
            _grid.setChar(cmd.x, cmd.y, cmd.char);
            break;
          case ClearCmd():
            _grid.clear();
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
    port!.openReadWrite();
    _listenPort();
    } catch (_) {
      print("NO Picotracker connected!");
    } 
  }

  Future<void> _listenPort() async {
    SerialPortReader reader = SerialPortReader(port!, timeout: 10000);  

    subscription = reader.stream.listen((data) {
      print('received:$data');
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
          _grid.getRows(),          
        ),
      ),
    );
  }
}

const COLS = 32;
const ROWS = 24;

class PicoScreen extends StatelessWidget {
  final List<String> lines;

  const PicoScreen(this.lines, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: lines.map((l) => ScreenCharRow(l.characters.toList())).toList(),
    );
  }
}

class ScreenCharRow extends StatelessWidget {
  final List<String> rowChars;

  const ScreenCharRow(this.rowChars, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: rowChars
          .map((c) => Text(
                c,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      height: 0.75,
                      letterSpacing: 4,
                      fontSize: 32,
                    ),
              ))
          .toList(),
    );
  }
}

enum CommandType {
  DRAW(3),
  CLEAR(1);

  const CommandType(this.byteCount);
  final int byteCount;
}

class CmdBuilder {
  CommandType? _type;
  final List<int> _byteBuffer = [];
  final _commandStreamController = StreamController<Command>.broadcast();

  Stream<Command> get commands => _commandStreamController.stream;

  void addByte(int byte) {
    switch (byte) {
      case 0xFD:
        _reset();
        _type = CommandType.DRAW;
        break;
      case 0xFC:
        _reset();
        _type = CommandType.CLEAR;
        break;
      default:
        if (_type != null && _byteBuffer.length != _type!.byteCount) {
          _byteBuffer.add(byte);
        } 
    }    
    _build();
  }

  // build command if we have all the bytes for it
  void _build() {
    switch (_type) {
      case CommandType.DRAW:
        if (_byteBuffer.length == _type!.byteCount) {
          final cmd = DrawCmd(
              char: _byteBuffer[0],
            // x & y co-ords are 1 indexed to avoid sending null chars in the serial data
            x: _byteBuffer[1],
            y: _byteBuffer[2],
          );
          if (cmd.x > 31 || cmd.y > 23) {
            print("BAD DATA: ${cmd.x} ${cmd.y} [${cmd.char}]");
          } else {
            _commandStreamController.add(cmd);
          }          
        }
        break;
      case CommandType.CLEAR:
        if (_byteBuffer.length == _type!.byteCount) {
          final cmd = ClearCmd(colour: _byteBuffer[0] - 1);
          _commandStreamController.add(cmd);
        }
        break;
      case null:
        break;
    }
  }

  void _reset() {
    _byteBuffer.clear();
    _type = null;
  }
}

abstract class Command {}

class DrawCmd implements Command {
  final int char;
  final int x;
  final int y;

  DrawCmd({required this.char, required this.x, required this.y});
}

class ClearCmd implements Command {
  final int colour;

  ClearCmd({required this.colour});
}
