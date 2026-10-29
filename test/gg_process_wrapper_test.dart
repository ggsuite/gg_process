// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
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
        const ggProcess = GgProcessWrapper();

        // Make a test call
        final result = await ggProcess.run(_dart, ['--version']);
        expect(result.exitCode, 0);
        final output = result.stdout;
        expect(output, contains('Dart'));
      });
    });

    // #########################################################################
    group('start', () {
      test('should map to Process.start', () async {
        const ggProcess = GgProcessWrapper();

        // Make a test call
        final done = Completer<void>();
        String result = '';
        final process = await ggProcess.start(_dart, ['--version']);
        process.stdout.listen(
          (data) {
            result += utf8.decode(data);
          },
          onDone: () {
            done.complete();
          },
        );

        await process.exitCode;
        await done.future;

        expect(result, contains('Dart'));
      });
    });
  });
}
