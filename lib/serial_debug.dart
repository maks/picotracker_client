import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var availablePorts = [];

  void __sendCmd() {}

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    setState(() => availablePorts = SerialPort.availablePorts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Scrollbar(
        child: ListView(
          children: [
            for (final address in availablePorts)
              Builder(builder: (context) {
                final port = SerialPort(address);
                return ExpansionTile(
                  title: Text(address),
                  children: [
                    CardListTile('Description', port.description),
                    CardListTile('Transport', port.transport.toTransport()),
                    CardListTile('USB Bus', port.busNumber?.toPadded()),
                    CardListTile('USB Device', port.deviceNumber?.toPadded()),
                    CardListTile('Vendor ID', port.vendorId?.toHex()),
                    CardListTile('Product ID', port.productId?.toHex()),
                    CardListTile('Manufacturer', port.manufacturer),
                    CardListTile('Product Name', port.productName),
                    CardListTile('Serial Number', port.serialNumber),
                    CardListTile('MAC Address', port.macAddress),
                  ],
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: __sendCmd,
        tooltip: 'send',
        child: const Icon(Icons.add),
      ),
    );
  }
}

extension IntToString on int {
  String toHex() => '0x${toRadixString(16)}';
  String toPadded([int width = 3]) => toString().padLeft(width, '0');
  String toTransport() {
    switch (this) {
      case SerialPortTransport.usb:
        return 'USB';
      case SerialPortTransport.bluetooth:
        return 'Bluetooth';
      case SerialPortTransport.native:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

class CardListTile extends StatelessWidget {
  final String name;
  final String? value;

  const CardListTile(this.name, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(value ?? 'N/A'),
        subtitle: Text(name),
      ),
    );
  }
}
