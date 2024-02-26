// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_process/src/gg_process_mock.dart';
import 'package:test/test.dart';

void main() {
  group('GgProcessMock', () {
    // #########################################################################
    group('run()', () {
      test('should return the fake result specified in constructor', () async {
        final fakeResult = ProcessResult(0, 0, 'Faked Result', '');
        final ggProcess = GgProcessMock(fakeResult: fakeResult);
        final result = await ggProcess.run('echo', ['Hello World']);
        expect(result, fakeResult);

        // Should also fill calls with the call parameters
        expect(ggProcess.calls, hasLength(1));

        final expectedCall = CallArguments(
          executable: 'echo',
          arguments: ['Hello World'],
          workingDirectory: null,
          environment: null,
          includeParentEnvironment: true,
          runInShell: false,
          stdoutEncoding: null,
          stderrEncoding: null,
        );
        expect(ggProcess.calls.first, expectedCall);

        // call.dryRun should be false, because no --dry-run argument was given
        expect(ggProcess.calls.first.dryRun, false);

        // call.dryRun should be true, when --dry-run argument was given
        ggProcess.run('echo', ['Hello World', '--dry-run']);
        expect(ggProcess.calls.last.dryRun, true);

        // call.hashCode should be the same as expectedCall.hashCode
        expect(expectedCall.hashCode, ggProcess.calls.first.hashCode);
      });
    });

    // #########################################################################
    group('start()', () {
      test('should throw an unimplemented error', () {
        final ggProcess = GgProcessMock();
        expect(
          () async => await ggProcess.start('echo', ['Hello World']),
          throwsUnimplementedError,
        );
      });
    });
  });
}
