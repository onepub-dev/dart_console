import 'dart:ffi';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:dart_console/src/ffi/unix/termios.dart';
import 'package:ffi/ffi.dart';

void main(List<String> args) {
  final libc = Platform.isMacOS
      ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
      : DynamicLibrary.open('libc.so.6');
  final libutil = Platform.isMacOS ? libc : DynamicLibrary.open('libutil.so.1');
  final openpty = libutil
      .lookupFunction<
        Int32 Function(
          Pointer<Int32>,
          Pointer<Int32>,
          Pointer<Char>,
          Pointer<Void>,
          Pointer<WinSize>,
        ),
        int Function(
          Pointer<Int32>,
          Pointer<Int32>,
          Pointer<Char>,
          Pointer<Void>,
          Pointer<WinSize>,
        )
      >('openpty');
  final dup2 = libc
      .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
        'dup2',
      );
  final close = libc.lookupFunction<Int32 Function(Int32), int Function(int)>(
    'close',
  );
  final master = calloc<Int32>();
  final slave = calloc<Int32>();
  final size = calloc<WinSize>()
    ..ref.ws_col = int.parse(args[0])
    ..ref.ws_row = int.parse(args[1]);
  var opened = false;

  try {
    if (openpty(master, slave, nullptr, nullptr, size) != 0) {
      throw StateError('Could not open a pseudo-terminal');
    }
    opened = true;
    if (dup2(slave.value, 0) == -1 || dup2(slave.value, 1) == -1) {
      throw StateError('Could not attach the pseudo-terminal');
    }

    final console = Console();
    if (!console.hasTerminal) {
      throw StateError('Expected a terminal');
    }
    // Keep stderr piped to the parent, since stdout now belongs to the PTY.
    stderr.writeln('SIZE:${console.windowWidth}x${console.windowHeight}');
  } finally {
    if (opened) {
      close(slave.value);
      close(master.value);
    }
    calloc.free(size);
    calloc.free(slave);
    calloc.free(master);
  }
  // Return normally so the parent can detect VM shutdown crashes as well.
}
