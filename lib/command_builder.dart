// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:async';

import 'commands.dart';

enum CommandType {
  DRAW(4),
  CLEAR(1),
  COLOUR(1);

  const CommandType(this.paramCount);
  final int paramCount;
}

class CmdBuilder {
  CommandType? _type;
  final List<int> _byteBuffer = [];
  bool cmdStarted = false;
  final _commandStreamController = StreamController<Command>.broadcast();

  Stream<Command> get commands => _commandStreamController.stream;

  void addByte(int byte) {
    if (byte == 0xFD) {
      if (cmdStarted) {
        //print("INCOMPLETE CMD:[$_type] $_byteBuffer");
      }
      _reset();
      cmdStarted = true;
    } else if (_type == null && cmdStarted) {
      switch (byte) {
        case 0x32:
          _type = CommandType.DRAW;
          break;
        case 0x33:
          _type = CommandType.CLEAR;
          break;
        case 0x34:
          _type = CommandType.COLOUR;
          break;
        default:
          print("INVALID COMMAND TYPE!!!!! [$byte]");
      }
    }
    else {
      if (cmdStarted) {
        _byteBuffer.add(byte);
      }
    }
    _build();
  }

  // build command if we have all the bytes for it
  void _build() {
    switch (_type) {
      case CommandType.DRAW:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = DrawCmd(
            char: _byteBuffer[0],
            // x & y co-ords are 1 indexed to avoid sending null chars in the serial data
            x: _byteBuffer[1] - ASCII_SPACE,
            y: _byteBuffer[2] - ASCII_SPACE,
            invert: _byteBuffer[3] == 127,
          );
          _reset();
          if (cmd.x > 31 || cmd.y > 23) {
            print("BAD DRAW DATA:${cmd.x} ${cmd.y} [${cmd.char}]");
          } else {
            _commandStreamController.add(cmd);
          }
        }
        break;
      case CommandType.CLEAR:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = ClearCmd(colour: _byteBuffer[0] - ASCII_SPACE);
          _commandStreamController.add(cmd);
          _reset();
        }
        break;
      case CommandType.COLOUR:
        if (_byteBuffer.length == _type!.paramCount) {
          final cmd = ColourCmd(colour: _byteBuffer[0] - ASCII_SPACE);
          _commandStreamController.add(cmd);
          _reset();
        }
        break;
      case null:
        break;
    }
  }

  void _reset() {
    _byteBuffer.clear();
    _type = null;
    cmdStarted = false;
  }
}
