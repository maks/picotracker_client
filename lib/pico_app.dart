import 'package:flutter/material.dart';
import 'package:picotracker_client/main_screen.dart';


class PicoApp extends StatelessWidget {
  const PicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'picoTracker',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: "Square"),
      home: const MainScreen(title: 'picoTracker'),
    );
  }
}

