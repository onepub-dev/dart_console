# CI architecture coverage

The package declares Linux, macOS, and Windows without CPU restrictions.
The current Dart support table lists Linux x64, ARM32, ARM64, and RISC-V;
macOS x64 and ARM64; and Windows x64 and ARM64. IA32 is unsupported by
current Dart. Linux here means glibc: the implementation loads libc.so.6.

The workflow explicitly selects six native hosted OS/CPU pairs and verifies
stable Dart on each, plus the declared minimum Dart 3.10.0 on Linux x64.
Unix tests execute the PTY helper in both JIT and AOT modes; Windows runs the
remaining suite and skips the Unix-specific PTY tests.

## Unresolved targets

Linux ARM32 and Linux RISC-V have no standard GitHub-hosted runner labels.
They are not silently treated as covered by ubuntu-24.04. Completing coverage
requires either a reviewed QEMU userspace/container setup on a disposable
hosted runner, with matching glibc and Dart SDK, or isolated ephemeral native
runners. Do not run fork PR code on persistent self-hosted machines containing
credentials. RISC-V SDK installation also requires verification beyond the
setup-dart action's documented architecture list.

Before advertising ARM32 support, correct the pre-existing TermIOS definition:
it uses the macOS layout (44 bytes on a 32-bit ABI), while Linux glibc uses a
60-byte struct. tcgetattr can therefore overrun the allocation on ARM32.
The macOS layout is also incorrect for Linux 64-bit field accesses, although
its larger allocation avoids this specific overflow. This issue predates the
ioctl variadic fix and requires separate platform-specific termios work.

Workflow configuration is not evidence of a completed platform test run.
Record actual runs and results before claiming a target passed.

Sources:
- https://dart.dev/get-dart#system-requirements
- https://docs.github.com/en/actions/reference/runners/github-hosted-runners
- https://github.com/dart-lang/setup-dart/blob/main/action.yml
- https://github.com/bminor/glibc/blob/master/sysdeps/unix/sysv/linux/bits/termios-struct.h
