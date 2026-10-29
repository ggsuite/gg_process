// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'dart:io';

import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

/// The running Dart executable: a real program on every operating system.
final _dart = Platform.resolvedExecutable;

void main() {
  group('GgProcess', () {
    // #########################################################################
    group('run()', () {
      test('should map to Process.run', () async {
        const wrapper = GgProcessWrapper();

        // Make a test call
        final result = await wrapper.run(_dart, ['--version']);
        expect(result.exitCode, 0);
        final output = result.stdout as String;
        expect(output, contains('Dart'));
      });
    });

    // #########################################################################
    group('start', () {
      test('should map to Process.start', () async {
        const wrapper = GgProcessWrapper();

        // Make a test call
        String result = '';
        final process = await wrapper.start(_dart, ['--version']);
        process.stdout.listen((data) {
          result += utf8.decode(data);
        });
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final exitCode = await process.exitCode;
        expect(exitCode, 0);
        expect(result, contains('Dart'));
      });
    });
  });
}
