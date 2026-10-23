# CI architecture coverage

The package declares Linux, macOS, and Windows, without a documented CPU
support matrix. Its README records tests on those operating systems; the
changelog mentions an ARM64 compatibility fix. Neither explicitly promises
ARM32 or RISC-V support. This workflow targets six native x64/ARM64 combinations.

Dart additionally supports Linux ARM32 and RISC-V. Those are potential package
expansion targets, not established dart_console support promises. Current Dart
does not support IA32. Linux here means glibc: the implementation loads libc.so.6.

The workflow explicitly selects six native hosted OS/CPU pairs and verifies
stable Dart on each, plus the declared minimum Dart 3.10.0 on Linux x64.
Unix tests execute the PTY helper in both JIT and AOT modes; Windows runs the
remaining suite and skips the Unix-specific PTY tests. Native Unix regressions
compile `test/termios_native.c` with the system `cc` against the runner's actual
headers. Local contributors need a C compiler (Linux build tools or macOS
Command Line Tools) to run these tests; consumers do not need one.

The macOS ARM64 job also runs a negative control in a temporary source copy:
it restores the old nonvariadic ioctl signature and requires the targeted JIT
and AOT tests to fail with an incorrect native result or a signal-killed helper.
The checked-out production source remains unchanged.

## Potential expansion targets

Linux ARM32 and Linux RISC-V have no standard GitHub-hosted runner labels.
They are not silently treated as covered by ubuntu-24.04. Completing coverage
requires either a reviewed QEMU userspace/container setup on a disposable
hosted runner, with matching glibc and Dart SDK, or isolated ephemeral native
runners. Do not run fork PR code on persistent self-hosted machines containing
credentials. RISC-V SDK installation also requires verification beyond the
setup-dart action's documented architecture list.

The prior code used the macOS termios layout on Linux. Separate glibc and Darwin
structs now correct that mismatch, and raw-mode flag masks come from libc's
cfmakeraw. Native C regression probes verify the host headers against Dart
fields and PTY mode restoration on the tested Unix targets. ARM32 and RISC-V
still need actual execution before claiming package support.

Workflow configuration is not evidence of a completed platform test run.
Record actual runs and results before claiming a target passed.

Sources:
- https://dart.dev/get-dart#system-requirements
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://github.com/dart-lang/setup-dart/blob/main/action.yml
- https://github.com/bminor/glibc/blob/master/sysdeps/unix/sysv/linux/bits/termios-struct.h
