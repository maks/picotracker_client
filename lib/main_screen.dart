// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picotracker_client/command_builder.dart';
import 'package:picotracker_client/picotracker/screen_char_grid.dart';
import 'package:picotracker_client/serialportinterface.dart';

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
  final _grid = ScreenCharGrid();
  final cmdBuilder = CmdBuilder();
  late final SerialPortHandler serialHandler;

  StreamSubscription? usbUdevStream;

  @override
  void initState() {
    super.initState();
    serialHandler = SerialPortHandler(cmdBuilder);

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
    usbUdevStream?.cancel();
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
        // _sendCmd(keymask);
      },
      child: Scaffold(
          backgroundColor: Colors.black,
          floatingActionButton: MaterialButton(
            child: const Text(
              "choose serial port",
              style: TextStyle(color: Colors.amberAccent),
            ),
            onPressed: () {
              serialHandler.chooseSerialDevice();
            },
          ),
          body: Stack(
            children: [
              PicoScreen(
                _grid,
                _grid.background,
              ),
            ],
          )),
    );
  }
}
