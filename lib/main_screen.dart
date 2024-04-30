// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:picotracker_client/command_builder.dart';
import 'package:picotracker_client/picotracker/screen_char_grid.dart';

import 'commands.dart';
import 'widgets/pico_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var availablePorts = <String>[];
  int keymask = 0;
  StreamSubscription? subscription;
  StreamSubscription? cmdStreamSubscription;
  SerialPort? port;
  final _grid = ScreenCharGrid();
  final cmdBuilder = CmdBuilder();

  void _sendCmd(int c) {
    // Input to track not working properly and disabled for now
    List<int> data = [c];
    Uint8List bytes = Uint8List.fromList(data);
    port!.write(bytes);
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
      port!.openReadWrite();
      _listenPort();
    } catch (_) {}
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
          debugPrint("DOWN:${event.logicalKey.keyLabel}");
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
          body: Stack(
        children: [
          Image.asset('assets/images/pico_background.jpg'),
          // hardcode position to align with background image given hardcoded window
          // size in my_application.cc for Linux
          Positioned(
            left: 60,
            top: 70,
            width: 320 * 1.6,
            height: 240 * 1.5,
            child: PicoScreen(
              _grid,
              _grid.background,
            ),
          ),
        ],
      )),
    );
  }
}
