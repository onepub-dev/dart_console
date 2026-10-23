import 'dart:ffi';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:dart_console/src/ffi/unix/termios.dart';
import 'package:dart_console/src/ffi/unix/termlib_unix.dart';
import 'package:ffi/ffi.dart';

void main(List<String> args) {
  final columns = int.parse(args[0]);
  final rows = int.parse(args[1]);
  final mode = args[2];
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
    ..ref.ws_col = columns
    ..ref.ws_row = rows;
  var opened = false;

  try {
    if (openpty(master, slave, nullptr, nullptr, size) != 0) {
      throw StateError('Could not open a pseudo-terminal');
    }
    opened = true;
    final descriptors = switch (mode) {
      'both' => [0, 1],
      'stdin' => [0],
      'stdout' => [1],
      'stderr' => [2],
      'none' => <int>[],
      _ => throw ArgumentError.value(mode),
    };
    for (final fd in descriptors) {
      if (dup2(slave.value, fd) == -1) {
        throw StateError('Could not attach the pseudo-terminal to $fd');
      }
    }

    // Query the package binding directly: Console can mask a failed ioctl
    // by falling back to dart:io's terminal dimensions.
    final terminal = TermLibUnix();
    if (sizeOf<WinSize>() != 8) throw StateError('Unexpected winsize layout');
    if (terminal.ioctl(
          -1,
          Platform.isMacOS ? TIOCGWINSZ_MACOS : TIOCGWINSZ_LINUX,
          size,
        ) !=
        -1) {
      throw StateError('Invalid descriptor should fail');
    }
    final expectedWidth = mode == 'none' || columns == 0 || rows == 0
        ? null
        : columns;
    final expectedHeight = expectedWidth == null ? null : rows;
    for (var i = 0; i < 100; i++) {
      if (terminal.windowWidth != expectedWidth ||
          terminal.windowHeight != expectedHeight) {
        throw StateError('Package ioctl returned incorrect dimensions');
      }
    }
    if (mode == 'both' && expectedWidth != null) {
      final console = Console();
      if (!console.hasTerminal ||
          console.windowWidth != columns ||
          console.windowHeight != rows) {
        throw StateError('Console returned incorrect dimensions');
      }
    }
    if (mode == 'none') {
      final console = Console();
      if (console.hasTerminal ||
          console.windowWidth != 80 ||
          console.windowHeight != 25) {
        throw StateError('Incorrect redirected-console fallback');
      }
    }
    // One output pipe always remains attached to the parent.
    (mode == 'stderr' ? stdout : stderr).writeln(
      'SIZE:$expectedWidth'
      'x$expectedHeight',
    );
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
