import 'package:flutter/foundation.dart';
import 'package:webserial/webserial.dart';
import 'dart:js_interop';

import 'command_builder.dart';

class SerialPortHandler {
  final CmdBuilder cmdBuilder;

  SerialPortHandler(this.cmdBuilder);

  void chooseSerialDevice() async {
    late final JSSerialPort? port;
    try {
      port = await requestWebSerialPort();
      debugPrint("got serial port: $port");
    } catch (e) {
      debugPrint(e.toString());
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

      debugPrint("port opened: ${port?.readable}");
    } else {
      debugPrint("port already opened: ${port?.readable}");
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
}
