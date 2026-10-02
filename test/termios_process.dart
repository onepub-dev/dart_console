import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:dart_console/src/ffi/unix/termlib_unix.dart';
import 'package:dart_console/src/ffi/unix/termios.dart';

Never _fail(String message) => throw StateError(message);

void _check(bool condition, String message) {
  if (!condition) _fail(message);
}

void _expectStateError(String label, void Function() action) {
  try {
    action();
  } on StateError {
    return;
  }
  _fail('$label did not throw StateError');
}

typedef _SizeNative = Size Function();
typedef _SizeDart = int Function();
typedef _FillNative = Void Function(Pointer<Void>);
typedef _FillDart = void Function(Pointer<Void>);
typedef _ValidateNative = Int32 Function(Pointer<Void>);
typedef _ValidateDart = int Function(Pointer<Void>);
typedef _OpenPtyNative = Int32 Function(Pointer<Int32>, Pointer<Int32>);
typedef _OpenPtyDart = int Function(Pointer<Int32>, Pointer<Int32>);
typedef _FdNative = Int32 Function(Int32);
typedef _FdDart = int Function(int);
typedef _Dup2Native = Int32 Function(Int32, Int32);
typedef _Dup2Dart = int Function(int, int);
typedef _ConfigureNative = Int32 Function(Int32);
typedef _ConfigureDart = int Function(int);
typedef _SnapshotNative = Int32 Function(Int32, Pointer<Void>);
typedef _SnapshotDart = int Function(int, Pointer<Void>);
typedef _CompareNative = Int32 Function(Int32, Pointer<Void>);
typedef _CompareDart = int Function(int, Pointer<Void>);

class _Native {
  _Native(String path) : library = DynamicLibrary.open(path);
  final DynamicLibrary library;

  int size(String name) =>
      library.lookupFunction<_SizeNative, _SizeDart>(name)();
  _FillDart get fill =>
      library.lookupFunction<_FillNative, _FillDart>('helper_fill_sentinels');
  _ValidateDart get validate =>
      library.lookupFunction<_ValidateNative, _ValidateDart>(
        'helper_validate_sentinels',
      );
  _OpenPtyDart get openPty =>
      library.lookupFunction<_OpenPtyNative, _OpenPtyDart>('helper_open_pty');
  _FdDart get closeFd =>
      library.lookupFunction<_FdNative, _FdDart>('helper_close_fd');
  _FdDart get dupFd =>
      library.lookupFunction<_FdNative, _FdDart>('helper_dup_fd');
  _Dup2Dart get dup2Fd =>
      library.lookupFunction<_Dup2Native, _Dup2Dart>('helper_dup2_fd');
  _ConfigureDart get configure =>
      library.lookupFunction<_ConfigureNative, _ConfigureDart>(
        'helper_configure_terminal',
      );
  _SnapshotDart get snapshot =>
      library.lookupFunction<_SnapshotNative, _SnapshotDart>('helper_snapshot');
  _CompareDart get rawMatches => library
      .lookupFunction<_CompareNative, _CompareDart>('helper_raw_matches');
  _CompareDart get snapshotMatches => library
      .lookupFunction<_CompareNative, _CompareDart>('helper_matches_snapshot');
}

void _checkLayout(_Native native) {
  final size = native.size('helper_termios_size');
  final buffer = calloc<Uint8>(size + 16);
  try {
    if (Platform.isMacOS) {
      _check(
        sizeOf<MacOSTermIOS>() == size,
        'MacOSTermIOS size differs from native sizeof(termios)',
      );
      final value = buffer.cast<MacOSTermIOS>();
      value.ref
        ..c_iflag = 0x11223344
        ..c_oflag = 0x22334455
        ..c_cflag = 0x33445566
        ..c_lflag = 0x44556677
        ..c_ispeed = 0x55667788
        ..c_ospeed = 0x66778899;
      for (var i = 0; i < 20; i++) {
        value.ref.c_cc[i] = (i * 11 + 3) & 0xff;
      }
      _check(
        native.validate(buffer.cast<Void>()) == 1,
        'C did not read the Dart macOS termios sentinels at native field offsets',
      );
      buffer.asTypedList(size).fillRange(0, size, 0);
      native.fill(buffer.cast<Void>());
      _check(
        value.ref.c_iflag == 0x11223344 &&
            value.ref.c_oflag == 0x22334455 &&
            value.ref.c_cflag == 0x33445566 &&
            value.ref.c_lflag == 0x44556677,
        'Dart could not read native macOS termios flags',
      );
      _check(
        value.ref.c_ispeed == 0x55667788 && value.ref.c_ospeed == 0x66778899,
        'Dart could not read native macOS termios speeds',
      );
      for (var i = 0; i < 20; i++) {
        _check(
          value.ref.c_cc[i] == ((i * 11 + 3) & 0xff),
          'Dart macOS control character $i has the wrong native offset',
        );
      }
    } else {
      _check(
        sizeOf<LinuxTermIOS>() == size,
        'LinuxTermIOS size differs from native sizeof(termios)',
      );
      final value = buffer.cast<LinuxTermIOS>();
      value.ref
        ..c_iflag = 0x11223344
        ..c_oflag = 0x22334455
        ..c_cflag = 0x33445566
        ..c_lflag = 0x44556677
        ..c_line = 0x5a
        ..c_ispeed = 0x55667788
        ..c_ospeed = 0x66778899;
      for (var i = 0; i < 32; i++) {
        value.ref.c_cc[i] = (i * 11 + 3) & 0xff;
      }
      _check(
        native.validate(buffer.cast<Void>()) == 1,
        'C did not read the Dart Linux termios sentinels at native field offsets',
      );
      buffer.asTypedList(size).fillRange(0, size, 0);
      native.fill(buffer.cast<Void>());
      _check(
        value.ref.c_iflag == 0x11223344 &&
            value.ref.c_oflag == 0x22334455 &&
            value.ref.c_cflag == 0x33445566 &&
            value.ref.c_lflag == 0x44556677 &&
            value.ref.c_line == 0x5a,
        'Dart could not read native Linux termios flags or c_line',
      );
      _check(
        value.ref.c_ispeed == 0x55667788 && value.ref.c_ospeed == 0x66778899,
        'Dart could not read native Linux termios speeds',
      );
      for (var i = 0; i < 32; i++) {
        _check(
          value.ref.c_cc[i] == ((i * 11 + 3) & 0xff),
          'Dart Linux control character $i has the wrong native offset',
        );
      }
    }
  } finally {
    calloc.free(buffer);
  }
}

void _checkCanaryAndRawMode(_Native native) {
  final originalStdin = native.dupFd(0);
  _check(originalStdin >= 0, 'dup(stdin) failed');
  final masterPointer = calloc<Int32>();
  final slavePointer = calloc<Int32>();
  final structSize = Platform.isMacOS
      ? sizeOf<MacOSTermIOS>()
      : sizeOf<LinuxTermIOS>();
  final nativeSize = native.size('helper_termios_size');
  _check(
    structSize == nativeSize,
    'Dart termios size differs from native sizeof(termios)',
  );
  final original = calloc<Uint8>(structSize);
  int master = -1;
  int slave = -1;
  try {
    _check(native.openPty(masterPointer, slavePointer) == 0, 'openpty failed');
    master = masterPointer.value;
    slave = slavePointer.value;
    _check(
      native.configure(slave) == 1,
      'could not configure PTY terminal modes and speeds',
    );

    final guardSize = structSize + 16;
    final guarded = calloc<Uint8>(guardSize);
    try {
      for (var i = guardSize - 16; i < guardSize; i++) {
        guarded[i] = 0xa5;
      }
      final terminal = TermLibUnix();
      _check(
        terminal.tcgetattr(slave, guarded.cast<Void>()) == 0,
        'tcgetattr on PTY slave failed',
      );
      for (var i = guardSize - 16; i < guardSize; i++) {
        _check(
          guarded[i] == 0xa5,
          'tcgetattr overwrote the trailing allocation canary at byte $i',
        );
      }
    } finally {
      calloc.free(guarded);
    }

    _check(
      native.snapshot(slave, original.cast<Void>()) == 1,
      'could not snapshot original PTY termios',
    );
    final terminalWithoutSnapshot = TermLibUnix();
    _check(native.dup2Fd(slave, 0) == 0, 'dup2(PTY slave, stdin) failed');
    terminalWithoutSnapshot.enableRawMode();
    _check(
      native.snapshotMatches(0, original.cast<Void>()) == 1,
      'enableRawMode changed the PTY after its initial stdin snapshot failed',
    );
    terminalWithoutSnapshot.disableRawMode();
    _check(
      native.snapshotMatches(0, original.cast<Void>()) == 1,
      'disableRawMode changed the PTY after its initial stdin snapshot failed',
    );
    final terminal = TermLibUnix();
    for (var cycle = 0; cycle < 2; cycle++) {
      terminal.enableRawMode();
      _check(
        native.rawMatches(0, original.cast<Void>()) == 1,
        'raw mode cycle $cycle does not match native termios.h flag and VMIN/VTIME expectations',
      );
      terminal.disableRawMode();
      _check(
        native.snapshotMatches(0, original.cast<Void>()) == 1,
        'disableRawMode cycle $cycle did not restore every original native terminal field',
      );
    }
    _check(
      native.closeFd(0) == 0,
      'could not close stdin for the tcsetattr error-path check',
    );
    _expectStateError(
      'enableRawMode after stdin closes',
      terminal.enableRawMode,
    );
    _expectStateError(
      'disableRawMode after stdin closes',
      terminal.disableRawMode,
    );
  } finally {
    native.dup2Fd(originalStdin, 0);
    native.closeFd(originalStdin);
    if (slave >= 0) native.closeFd(slave);
    if (master >= 0) native.closeFd(master);
    calloc.free(masterPointer);
    calloc.free(slavePointer);
    calloc.free(original);
  }
}

void main(List<String> arguments) {
  if (!Platform.isLinux && !Platform.isMacOS) return;
  if (arguments.length != 2) {
    _fail('usage: termios_process.dart <layout|pty|no-tty> <native-library>');
  }
  final native = _Native(arguments[1]);
  switch (arguments[0]) {
    case 'layout':
      _checkLayout(native);
      break;
    case 'pty':
      _checkCanaryAndRawMode(native);
      break;
    case 'no-tty':
      final terminal = TermLibUnix();
      terminal.enableRawMode();
      terminal.disableRawMode();
      break;
    default:
      _fail('unknown termios regression case: ${arguments[0]}');
  }
}
