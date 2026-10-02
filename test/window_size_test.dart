import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Future<String> runChild(String executable, List<String> arguments) async {
  final process = await Process.start(executable, arguments);
  final output = process.stdout.transform(utf8.decoder).join();
  final errors = process.stderr.transform(utf8.decoder).join();
  try {
    await process.stdin.close();
    final result = await Future.wait<Object>([
      process.exitCode,
      output,
      errors,
    ]).timeout(const Duration(seconds: 60));
    expect(result[0], 0, reason: '${result[1]}${result[2]}');
    return '${result[1]}${result[2]}'.trim();
  } finally {
    // SIGKILL also handles a child stuck in native code; await exit to reap it.
    process.kill(ProcessSignal.sigkill);
    await process.exitCode;
  }
}

void main() {
  group(
    'Unix terminal window size',
    () {
      late Directory temporary;
      late String executable;
      setUpAll(() async {
        temporary = await Directory.systemTemp.createTemp('dart-console-aot-');
        addTearDown(() => temporary.delete(recursive: true));
        executable = '${temporary.path}/window-size';
        await runChild(Platform.resolvedExecutable, [
          'compile',
          'exe',
          'test/window_size_process.dart',
          '-o',
          executable,
        ]);
      });
      for (final aot in [false, true]) {
        for (final (columns, rows, mode) in [
          (80, 24, 'both'),
          (137, 43, 'both'),
          (40001, 32769, 'both'),
          (137, 43, 'stdout'),
          (137, 43, 'stdin'),
          (137, 43, 'stderr'),
          (137, 43, 'none'),
          (0, 43, 'both'),
          (137, 0, 'both'),
        ]) {
          test(
            '${aot ? 'AOT' : 'JIT'} ${columns}x$rows $mode exits cleanly',
            () async {
              final output = await runChild(
                aot ? executable : Platform.resolvedExecutable,
                [
                  if (!aot) 'test/window_size_process.dart',
                  '$columns',
                  '$rows',
                  mode,
                ],
              );
              final valid = mode != 'none' && columns != 0 && rows != 0;
              expect(
                output,
                valid ? 'SIZE:${columns}x$rows' : 'SIZE:nullxnull',
              );
            },
          );
        }
      }
    },
    skip: !Platform.isMacOS && !Platform.isLinux,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
