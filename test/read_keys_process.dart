import 'dart:io';

import 'package:dart_console/dart_console.dart';

Future<void> main(List<String> args) async {
  final expectedKeys = int.parse(args.first);
  final console = Console();
  var receivedKeys = 0;

  await for (final key in console.readKeys(
    escapeTimeout: const Duration(milliseconds: 10),
  )) {
    if (key.isControl) {
      print('control:${key.controlChar.name}');
    } else {
      print('printable:${key.char}');
    }

    receivedKeys++;
    if (receivedKeys == expectedKeys) {
      break;
    }
  }

  exitCode = receivedKeys == expectedKeys ? 0 : 1;
}
