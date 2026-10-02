import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Unix terminal window size', () {
    for (final (columns, rows) in [(80, 24), (137, 43)]) {
      test('reads ${columns}x$rows and exits cleanly', () async {
        final process = await Process.start(Platform.resolvedExecutable, [
          'run',
          'test/window_size_process.dart',
          '$columns',
          '$rows',
        ], workingDirectory: Directory.current.path);
        addTearDown(() => process.kill());
        await process.stdin.close();

        final stdout = process.stdout.transform(utf8.decoder).join();
        final stderr = process.stderr.transform(utf8.decoder).join();
        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 10),
        );
        final output = await stderr;
        await stdout;

        expect(exitCode, 0, reason: output);
        expect(output.trim(), 'SIZE:${columns}x$rows');
      });
    }
  }, skip: !Platform.isMacOS && !Platform.isLinux);
}
