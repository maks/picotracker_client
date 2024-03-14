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
  final ByteData _charBytes = Uint8List(COLS * ROWS).buffer.asByteData();

  ByteData get data => _charBytes;

  int getChar(int x, int y) {
    return _charBytes.getUint8((y * COLS) + x);
  }

  void setChar(int x, int y, int char) {
    _charBytes.setUint8((y * COLS) + x, char);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var availablePorts = <String>[];
  int keymask = 0;
  StreamSubscription? subscription;
  SerialPort? port;
  final _grid = ScreenCharGrid();

  void _sendCmd(int c) {
    List<int> data = [c];
    Uint8List bytes = Uint8List.fromList(data);
    print(port!.write(bytes));
  }

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  @override
  void dispose() {
    super.dispose();
    subscription?.cancel();
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
      //07 ascii is bell char
      if (byteBuf.getUint8(0) == 9) {
        for (int i = 0; i < byteBuf.lengthInBytes;) {
          i++; //skip tab
          final x = byteBuf.getUint8(i++);
          final y = byteBuf.getUint8(i++);
          final c = byteBuf.getUint8(i++);

          print("char data: x:$x y:$y c:${String.fromCharCode(c)}");
        }
      } else {
        print("usb:${String.fromCharCodes(data)}");
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
          List<String>.filled(ROWS, "M" * 32),
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
