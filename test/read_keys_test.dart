import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('readKeys subprocess', () {
    test('readKeys streams printable and control keys', () async {
      final keys = await _readKeys([0x61, 0x03, 0x7f], expectedKeys: 3);

      expect(keys, ['printable:a', 'control:ctrlC', 'control:backspace']);
    });

    test('readKeys streams escape sequences', () async {
      final keys = await _readKeys([
        0x1b,
        0x5b,
        0x41,
        0x1b,
        0x5b,
        0x33,
        0x7e,
        0x1b,
        0x4f,
        0x50,
      ], expectedKeys: 3);

      expect(keys, ['control:arrowUp', 'control:delete', 'control:F1']);
    });

    test('readKeys streams escape key when no sequence follows', () async {
      final keys = await _readKeys([0x1b], expectedKeys: 1);

      expect(keys, ['control:escape']);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Future<List<String>> _readKeys(
  List<int> bytes, {
  required int expectedKeys,
}) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'test/read_keys_process.dart',
    '$expectedKeys',
  ], workingDirectory: Directory.current.path);

  final stdout = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  final stderr = process.stderr.transform(utf8.decoder).join();
  try {
    process.stdin.add(bytes);
    await process.stdin.close();
    // Include cold JIT startup in the bounded wait, and drain both pipes
    // concurrently. The outer test timeout must leave time for cleanup.
    final result = await Future.wait<Object>([
      process.exitCode,
      stdout,
      stderr,
    ]).timeout(const Duration(seconds: 60));
    expect(result[0], 0, reason: result[2] as String);
    return result[1] as List<String>;
  } finally {
    process.kill(
      Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigkill,
    );
    await process.exitCode;
  }
}
