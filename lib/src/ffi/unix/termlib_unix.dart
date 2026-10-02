// termlib-unix.dart
//
// glibc-dependent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../termlib.dart';
import 'termios.dart';
import 'unistd.dart';

class TermLibUnix implements TermLib {
  late final DynamicLibrary _stdlib;

  // Keep the snapshot in managed memory; temporary native buffers are freed
  // on every path. A failed tcgetattr must never become a zeroed restore state.
  Uint8List? _originalTermios;
  late final CFMakeRawDart _cfmakeraw;

  int get _termiosSize =>
      Platform.isMacOS ? sizeOf<MacOSTermIOS>() : sizeOf<LinuxTermIOS>();

  late final TCGetAttrDart tcgetattr;
  late final TCSetAttrDart tcsetattr;
  late final IOCtlDart ioctl;

  int get _windowSizeRequest =>
      Platform.isMacOS ? TIOCGWINSZ_MACOS : TIOCGWINSZ_LINUX;

  int? _readWindowSize(int Function(WinSize size) value) {
    final winsize = calloc<WinSize>();
    try {
      for (final fd in [STDOUT_FILENO, STDIN_FILENO, STDERR_FILENO]) {
        if (ioctl(fd, _windowSizeRequest, winsize) == 0 &&
            winsize.ref.ws_col > 0 &&
            winsize.ref.ws_row > 0) {
          return value(winsize.ref);
        }
      }
      return null;
    } finally {
      calloc.free(winsize);
    }
  }

  @override
  int? get windowHeight => _readWindowSize((size) => size.ws_row);

  @override
  int? get windowWidth => _readWindowSize((size) => size.ws_col);

  @override
  int setWindowHeight(int height) {
    stdout.write('\x1b[8;$height;t');
    return height;
  }

  @override
  int setWindowWidth(int width) {
    stdout.write('\x1b[8;;${width}t');
    return width;
  }

  void _applyTermios({required bool raw}) {
    final original = _originalTermios;
    if (original == null) return;
    final buffer = calloc<Uint8>(_termiosSize);
    try {
      buffer.asTypedList(_termiosSize).setAll(0, original);
      if (raw) {
        _cfmakeraw(buffer.cast());
        if (Platform.isMacOS) {
          final state = buffer.cast<MacOSTermIOS>().ref;
          state.c_cc[VMIN_MACOS] = 0;
          state.c_cc[VTIME_MACOS] = 1;
        } else {
          final state = buffer.cast<LinuxTermIOS>().ref;
          state.c_cc[VMIN_LINUX] = 0;
          state.c_cc[VTIME_LINUX] = 1;
        }
      }
      if (tcsetattr(STDIN_FILENO, TCSANOW, buffer.cast()) != 0) {
        throw StateError(
          'Could not ${raw ? "enable" : "restore"} terminal mode',
        );
      }
    } finally {
      calloc.free(buffer);
    }
  }

  @override
  void enableRawMode() => _applyTermios(raw: true);

  @override
  void disableRawMode() => _applyTermios(raw: false);

  TermLibUnix() {
    _stdlib = Platform.isMacOS
        ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
        : DynamicLibrary.open('libc.so.6');

    tcgetattr = _stdlib.lookupFunction<TCGetAttrNative, TCGetAttrDart>(
      'tcgetattr',
    );
    tcsetattr = _stdlib.lookupFunction<TCSetAttrNative, TCSetAttrDart>(
      'tcsetattr',
    );
    ioctl = _stdlib.lookupFunction<IOCtlNative, IOCtlDart>('ioctl');
    _cfmakeraw = _stdlib.lookupFunction<CFMakeRawNative, CFMakeRawDart>(
      'cfmakeraw',
    );

    final buffer = calloc<Uint8>(_termiosSize);
    try {
      if (tcgetattr(STDIN_FILENO, buffer.cast()) == 0) {
        _originalTermios = Uint8List.fromList(buffer.asTypedList(_termiosSize));
      }
    } finally {
      calloc.free(buffer);
    }
  }
}
