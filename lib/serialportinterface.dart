export 'serialport_none.dart'
    if (dart.library.io) 'serialport_native.dart'
    if (dart.library.js_interop) 'serialport_web.dart';
