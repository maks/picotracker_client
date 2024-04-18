// ignore_for_file: constant_identifier_names, non_constant_identifier_names


import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:picotracker_client/pico_app.dart';



void main() {
  runApp(const PicoApp());
  try {
    SerialPort('/dev/ttyACM0').close();
  } catch (e) {
    // ignore: avoid_print
    print("could not close serial port $e");
  }
}
