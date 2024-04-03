// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  group('GgFakeProcess', () {
    test('should work fine', () async {
      // Create a new instance of GgFakeProcess
      final process = GgFakeProcess();

      // Create a new instance of GgFakeProcess and pass the instance of
      // GgFakeProcess to it
      final processWrapper = MockGgProcessWrapper();
      when(() => processWrapper.start(any(), any())).thenAnswer((_) async {
        return process;
      });

      // start the process
      final result = await processWrapper.start('executable', ['arg1', 'arg2']);
      expect(result, process);

      // Listen to the stdout and stderr streams, as well as the exitCode
      final stdouts = <String>[];
      result.stdout.map((event) => utf8.decode(event)).listen(stdouts.add);

      final stderrs = <String>[];
      result.stderr.map((event) => utf8.decode(event)).listen(stderrs.add);

      // Push some data to the stdout
      process.pushToStdout.add('stdout1');
      expect(stdouts, ['stdout1']);
      process.pushToStdout.add('stdout2');
      expect(stdouts, ['stdout1', 'stdout2']);

      // Push some data to the stderr
      process.pushToStderr.add('stderr1');
      expect(stderrs, ['stderr1']);
      process.pushToStderr.add('stderr2');
      expect(stderrs, ['stderr1', 'stderr2']);

      // Push the exitCode
      process.exit(5);
      final exitCode = await process.exitCode;
      expect(exitCode, 5);

      // Check if the stdout and stderr streams are closed
      expect(process.pushToStdout.isClosed, isTrue);
      expect(process.pushToStderr.isClosed, isTrue);

      // Write some data to the stdin
      process.stdin.write('stdin1');

      // PID should be 0
      expect(result.pid, 0);

      // Kill the process
      final isNotNull = result.kill();
      expect(isNotNull, isTrue);

      expect(true, isNotNull);
    });

    group('exitWithException(exception)', () {
      test('should finish the process', () async {
        // Create a new instance of GgFakeProcess
        final process = GgFakeProcess();

        // Create a new instance of GgFakeProcess and pass the instance of
        // GgFakeProcess to it
        final processWrapper = MockGgProcessWrapper();
        when(() => processWrapper.start(any(), any())).thenAnswer((_) async {
          return process;
        });

        // start the process
        final result =
            await processWrapper.start('executable', ['arg1', 'arg2']);
        expect(result, process);

        // Let the process exit with an exception
        process.exitWithException(Exception('An exception'));

        late String exception;

        try {
          await process.exitCode;
        } catch (e) {
          exception = e.toString();
        }

        expect(exception, 'Exception: An exception');
      });
    });
  });
}
