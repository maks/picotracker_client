import 'package:flutter/material.dart';
import 'package:picotracker_client/main_screen.dart';

class PicoApp extends StatelessWidget {
  const PicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "H: ${MediaQuery.of(context).size.height} W: ${MediaQuery.of(context).size.width}");
    return MaterialApp(
      title: 'picoTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: "Hourglass",
      ),
      home: const MainScreen(title: 'picoTracker'),
    );
  }
}
