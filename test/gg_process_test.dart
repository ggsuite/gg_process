// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

void main() {
  group('GgProcess', () {
    // #########################################################################
    group('run()', () {
      test('should map to Process.run', () async {
        const wrapper = GgProcessWrapper();

        // Make a test call
        final result = await wrapper.run('echo', ['Hello World']);
        expect(result.exitCode, 0);
        final output = result.stdout as String;
        expect(output, contains('Hello World'));
      });
    });

    // #########################################################################
    group('start', () {
      test('should map to Process.start', () async {
        const wrapper = GgProcessWrapper();

        // Make a test call
        String result = '';
        final process = await wrapper.start('echo', ['Hello World']);
        process.stdout.listen((data) {
          result += utf8.decode(data);
        });
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final exitCode = await process.exitCode;
        expect(exitCode, 0);
        expect(result, contains('Hello World'));
      });
    });
  });
}
