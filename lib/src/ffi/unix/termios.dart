// termios.dart
//
// Dart representations of functions and constants used in termios.h

// Ignore these lints, since these are UNIX identifiers that we're replicating
//
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, camel_case_types

import 'dart:ffi';

// Layouts from glibc bits/termios-struct.h and Darwin sys/termios.h.
// These are different ABIs, even on the same CPU architecture.
// https://github.com/bminor/glibc/blob/master/sysdeps/unix/sysv/linux/bits/termios-struct.h
// https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/termios.h
base class LinuxTermIOS extends Struct {
  @UnsignedInt()
  external int c_iflag;
  @UnsignedInt()
  external int c_oflag;
  @UnsignedInt()
  external int c_cflag;
  @UnsignedInt()
  external int c_lflag;
  @UnsignedChar()
  external int c_line;
  @Array(32)
  external Array<UnsignedChar> c_cc;
  @UnsignedInt()
  external int c_ispeed;
  @UnsignedInt()
  external int c_ospeed;
}

base class MacOSTermIOS extends Struct {
  @UnsignedLong()
  external int c_iflag;
  @UnsignedLong()
  external int c_oflag;
  @UnsignedLong()
  external int c_cflag;
  @UnsignedLong()
  external int c_lflag;
  @Array(20)
  external Array<UnsignedChar> c_cc;
  @UnsignedLong()
  external int c_ispeed;
  @UnsignedLong()
  external int c_ospeed;
}

// TCSANOW is zero on both supported Unix platforms.
const int TCSANOW = 0;
const int VMIN_LINUX = 6;
const int VTIME_LINUX = 5;
const int VMIN_MACOS = 16;
const int VTIME_MACOS = 17;
const int TIOCGWINSZ_LINUX = 0x5413;
const int TIOCGWINSZ_MACOS = 0x40087468;

// struct winsize {
//   unsigned short ws_row;
//   unsigned short ws_col;
//   unsigned short ws_xpixel;
//   unsigned short ws_ypixel;
// };
base class WinSize extends Struct {
  @UnsignedShort()
  external int ws_row;
  @UnsignedShort()
  external int ws_col;
  @UnsignedShort()
  external int ws_xpixel;
  @UnsignedShort()
  external int ws_ypixel;
}

// int tcgetattr(int, struct termios *);
typedef TCGetAttrNative = Int32 Function(Int32 fildes, Pointer<Void> termios);
typedef TCGetAttrDart = int Function(int fildes, Pointer<Void> termios);

// int tcsetattr(int, int, const struct termios *);
typedef TCSetAttrNative =
    Int32 Function(Int32 fildes, Int32 optional_actions, Pointer<Void> termios);
typedef TCSetAttrDart =
    int Function(int fildes, int optional_actions, Pointer<Void> termios);

// int ioctl(int, unsigned long, ...);
// The winsize pointer is variadic, which matters for the macOS ARM64 ABI.
typedef IOCtlNative =
    Int32 Function(
      Int32 fildes,
      UnsignedLong request,
      VarArgs<(Pointer<WinSize>,)> winsize,
    );
typedef IOCtlDart =
    int Function(int fildes, int request, Pointer<WinSize> winsize);

// void cfmakeraw(struct termios *);
// Let libc apply its own platform-specific flag masks.
typedef CFMakeRawNative = Void Function(Pointer<Void> termios);
typedef CFMakeRawDart = void Function(Pointer<Void> termios);
