// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:picotracker_client/command_builder.dart';
import 'package:picotracker_client/picotracker/screen_char_grid.dart';

import 'commands.dart';
import 'widgets/pico_screen.dart';
import 'package:webserial/webserial.dart';
import 'dart:js_interop';

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
  // SerialPort? port;
  final _grid = ScreenCharGrid();
  final cmdBuilder = CmdBuilder();

  StreamSubscription? usbUdevStream;

  @override
  void initState() {
    super.initState();

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

  void chooseSerialDevice() async {
    late final JSSerialPort? port;
    try {
      port = await requestWebSerialPort();
      print("got serial port: $port");
    } catch (e) {
      print(e);
      return;
    }

    if (port?.readable == null) {
      // Open the serial port.
      await port
          ?.open(
            JSSerialOptions(
              baudRate: 115200,
              dataBits: 8,
              stopBits: 1,
              parity: "none",
              bufferSize: 64,
              flowControl: "none",
            ),
          )
          .toDart;

      print("port opened: ${port?.readable}");
    } else {
      print("port already opened: ${port?.readable}");
    }
    // Listen to data coming from the serial device.
    final reader = port?.readable?.getReader() as ReadableStreamDefaultReader;

    while (true) {
      final result = await reader.read().toDart;
      if (result.done) {
        // Allow the serial port to be closed later.
        reader.releaseLock();
        break;
      } else {
        // value is a Uint8Array.
        onSerialData(result.value as JSUint8Array);
      }
    }
  }

  void onSerialData(JSUint8Array data) {
    // print("$data");

    final byteBuf = data.toDart;
    for (int i = 0; i < byteBuf.lengthInBytes; i++) {
      cmdBuilder.addByte(byteBuf[i]);
    }
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
          floatingActionButton: MaterialButton(
            child: const Text("choose serial port"),
            onPressed: () {
              chooseSerialDevice();
            },
          ),
          body: Stack(
            children: [
              Image.asset(
                'assets/images/pico_background2.jpg',
                height: 600,
              ),
              // hardcode position to align with background image given hardcoded window
              // size in my_application.cc for Linux
              Positioned(
                left: 85,
                top: 86,
                width: 320 * 1.69,
                height: 240 * 1.7,
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
