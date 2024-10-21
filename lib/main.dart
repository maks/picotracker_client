import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:picotracker_client/pico_app.dart';

import 'main_screen.dart';



void main() {
  runApp(const PicoApp());
  try {
    SerialPort(linuxUsbTTY).close();
  } catch (e) {
    // ignore: avoid_print
    print("could not close serial port $e");
  }
}
