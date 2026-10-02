import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Future<String> _runChild(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments);
  final stdout = process.stdout.transform(utf8.decoder).join();
  final stderr = process.stderr.transform(utf8.decoder).join();
  try {
    await process.stdin.close();
    final result = await Future.wait<Object>([
      process.exitCode,
      stdout,
      stderr,
    ]).timeout(const Duration(seconds: 60));
    expect(result[0], 0, reason: '${result[1]}${result[2]}');
    return '${result[1]}${result[2]}'.trim();
  } finally {
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
  }
}

Future<void> _compileNative(String output) async {
  final args = <String>[
    if (Platform.isMacOS) '-dynamiclib' else ...['-shared', '-fPIC'],
    'test/termios_native.c',
    '-o',
    output,
    if (Platform.isLinux) '-lutil',
  ];
  await _runChild('cc', args);
}

void main() {
  group(
    'native Unix termios ABI and raw mode',
    () {
      late Directory temporary;
      late String nativeLibrary;
      late String aotExecutable;

      setUpAll(() async {
        temporary = await Directory.systemTemp.createTemp(
          'dart-console-termios-',
        );
        addTearDown(() => temporary.delete(recursive: true));
        nativeLibrary =
            '${temporary.path}/termios.${Platform.isMacOS ? 'dylib' : 'so'}';
        await _compileNative(nativeLibrary);
        aotExecutable = '${temporary.path}/termios-process';
        await _runChild(Platform.resolvedExecutable, [
          'compile',
          'exe',
          'test/termios_process.dart',
          '-o',
          aotExecutable,
        ]);
      });

      for (final aot in [false, true]) {
        for (final testCase in ['layout', 'pty', 'no-tty']) {
          test(
            '${aot ? 'AOT' : 'JIT'} $testCase matches the native Unix ABI',
            () async {
              await _runChild(
                aot ? aotExecutable : Platform.resolvedExecutable,
                [
                  if (!aot) 'test/termios_process.dart',
                  testCase,
                  nativeLibrary,
                ],
              );
            },
          );
        }
      }
    },
    skip: !Platform.isLinux && !Platform.isMacOS,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
