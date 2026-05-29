import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
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
}

Future<List<String>> _readKeys(
  List<int> bytes, {
  required int expectedKeys,
}) async {
  final process = await Process.start(Platform.resolvedExecutable, [
    'run',
    'test/read_keys_process.dart',
    '$expectedKeys',
  ], workingDirectory: Directory.current.path);

  process.stdin.add(bytes);
  await process.stdin.close();

  final stdout = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .toList();
  final stderr = await process.stderr.transform(utf8.decoder).join();
  final output = await stdout.timeout(const Duration(seconds: 10));
  final exitCode = await process.exitCode.timeout(const Duration(seconds: 10));

  expect(exitCode, 0, reason: stderr);
  return output;
}
