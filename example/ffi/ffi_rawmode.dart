// Use the package's platform-specific native bindings instead of duplicating
// the incompatible Linux and macOS termios layouts in this example.
import 'dart:io';

import 'package:dart_console/src/ffi/unix/termlib_unix.dart';

void main() {
  if (!Platform.isLinux && !Platform.isMacOS || !stdin.hasTerminal) {
    stderr.writeln('Run this example in a Linux or macOS terminal.');
    return;
  }
  final terminal = TermLibUnix();
  terminal.enableRawMode();
  try {
    stdout.write('RAW MODE: Here is some text.\nHere is some more text.\r\n');
  } finally {
    terminal.disableRawMode();
  }
  stdout.writeln('ORIGINAL MODE: Here is some text.');
}
