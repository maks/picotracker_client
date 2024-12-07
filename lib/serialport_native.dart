import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'command_builder.dart';

class SerialPortHandler {
  final CmdBuilder cmdBuilder;
  SerialPort? port;

  SerialPortHandler(this.cmdBuilder);

  void chooseSerialDevice() async {
    //TODO, for now just use hardcoded port
    try {
      String linuxUsbTTY = "/dev/ttyACM0";
      SerialPort(linuxUsbTTY).close();
    } catch (e) {
      // ignore: avoid_print
      print("could not close serial port $e");
    }
  }

  void onSerialData(var data) {
    // print("$data");

    final byteBuf = data.toDart;
    for (int i = 0; i < byteBuf.lengthInBytes; i++) {
      cmdBuilder.addByte(byteBuf[i]);
    }
  }
}
