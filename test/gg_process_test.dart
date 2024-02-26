// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_process/src/gg_process.dart';
import 'package:test/test.dart';

void main() {
  group('GgProcess', () {
    // #########################################################################
    group('run()', () {
      test('should map to Process.run', () async {
        final ggProcess = GgProcess();

        // Make a test call
        final result = await ggProcess.run('echo', ['Hello World']);
        expect(result.exitCode, 0);
        final output = utf8.decode(result.stdout as List<int>);
        expect(output, contains('Hello World'));
      });
    });

    // #########################################################################
    group('start', () {
      test('should map to Process.start', () async {
        final ggProcess = GgProcess();

        // Make a test call
        String result = '';
        final process = await ggProcess.start('echo', ['Hello World']);
        process.stdout.listen((data) {
          result += utf8.decode(data);
        });
        await process.exitCode;
        expect(result, contains('Hello World'));
      });
    });
  });
}
