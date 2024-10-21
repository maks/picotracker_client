// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:picotracker_client/command_builder.dart';
import 'package:picotracker_client/picotracker/screen_char_grid.dart';
import 'package:udev/udev.dart';

import 'commands.dart';
import 'widgets/pico_screen.dart';

const linuxUsbTTY = '/dev/ttyACM0';

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

  StreamSubscription? usbUdevStream;

  void _sendCmd(int c) {
    // Input to track not working properly and disabled for now
    List<int> data = [c];
    Uint8List bytes = Uint8List.fromList(data);
    port!.write(bytes);
  }

  @override
  void initState() {
    super.initState();

    initPort();
    listenForUsbDevices();

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

  void initPort() {
    // print("Init Port");
    setState(() => availablePorts = SerialPort.availablePorts);
    try {
      port = SerialPort(linuxUsbTTY);
      port!.openReadWrite();
      _listenPort();
    } catch (_) {}
  }

  Future<void> _listenPort() async {
    if (port == null) {
      print("null port can't listen");
      return;
    }
    SerialPortReader reader = SerialPortReader(port!, timeout: 20);

    subscription = reader.stream.listen((data) {
      final byteBuf = data.buffer.asByteData();
      for (int i = 0; i < byteBuf.lengthInBytes; i++) {
        cmdBuilder.addByte(byteBuf.getUint8(i));
      }
    });
  }

  void listenForUsbDevices() {
    final context = UdevContext();
    final stream = context.monitorDevices(subsystems: ['usb']);
    usbUdevStream = stream.listen((d) {
      // print("USBevent: $d");
      // d.properties.forEach((key, value) => print("$key:$value"));
      final ttyFile = File(linuxUsbTTY);
      if (ttyFile.existsSync() && port == null) {
        // print("found port file, so now do init");
        initPort();
      } else {
        // print("no more port, do close");
        port?.close();
        port = null;
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
