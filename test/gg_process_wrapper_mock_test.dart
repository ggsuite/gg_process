// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_process/src/gg_process_wrapper_mock.dart';
import 'package:gg_process/src/gg_process_mock.dart';
import 'package:test/test.dart';

void main() {
  group('GgProcessWrapperMock', () {
    // #########################################################################
    group('run()', () {
      test('should return the fake result specified in constructor', () async {
        final fakeResult = ProcessResult(0, 0, 'Faked Result', '');
        final processWrapper = GgProcessWrapperMock(runResult: fakeResult);
        final result = await processWrapper.run('echo', ['Hello World']);
        expect(result, fakeResult);

        // Should also fill calls with the call parameters
        expect(processWrapper.calls, hasLength(1));

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
        expect(processWrapper.calls.first, expectedCall);

        // call.dryRun should be false, because no --dry-run argument was given
        expect(processWrapper.calls.first.dryRun, false);

        // call.dryRun should be true, when --dry-run argument was given
        processWrapper.run('echo', ['Hello World', '--dry-run']);
        expect(processWrapper.calls.last.dryRun, true);

        // call.hashCode should be the same as expectedCall.hashCode
        expect(expectedCall.hashCode, processWrapper.calls.first.hashCode);
      });
    });

    // .......................................................................
    test('should return the fake result specified in constructor', () async {
      final process = GgProcessMock();
      final wrapper = GgProcessWrapperMock(onStart: (_) => process);
      final result = await wrapper.start('echo', ['Hello World']);
      expect(result, process);
      expect(wrapper.calls.last.executable, 'echo');
      expect(wrapper.calls.last.arguments, ['Hello World']);
      result.kill();
    });
  });
}
