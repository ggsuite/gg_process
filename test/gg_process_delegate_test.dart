// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

// .............................................................................
/// Records the calls it receives instead of executing anything.
class _RecordingDelegate extends GgProcessDelegate {
  _RecordingDelegate();

  final List<String> calls = [];

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) async {
    calls.add('run $executable ${arguments.join(' ')} @$workingDirectory');
    return ProcessResult(0, 0, 'recorded-stdout', 'recorded-stderr');
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    calls.add('start $executable ${arguments.join(' ')}');
    final process = GgFakeProcess();
    process.exit(0);
    return process;
  }
}

void main() {
  tearDown(() => GgProcessDelegate.current = null);

  group('GgProcessDelegate', () {
    // #########################################################################
    group('defaultDelegate', () {
      test('runs a process using dart:io', () async {
        final result = await GgProcessDelegate.defaultDelegate.run('echo', [
          'Hello World',
        ]);
        expect(result.exitCode, 0);
        expect(result.stdout, contains('Hello World'));
      });

      test('starts a process using dart:io', () async {
        final process = await GgProcessDelegate.defaultDelegate.start('echo', [
          'Hello World',
        ]);
        expect(await process.exitCode, 0);
      });

      test('is installed by default', () {
        expect(GgProcessDelegate.current, GgProcessDelegate.defaultDelegate);
      });
    });

    // #########################################################################
    group('current', () {
      test('can be replaced and reset', () {
        final delegate = _RecordingDelegate();
        GgProcessDelegate.current = delegate;
        expect(GgProcessDelegate.current, delegate);

        GgProcessDelegate.current = null;
        expect(GgProcessDelegate.current, GgProcessDelegate.defaultDelegate);
      });

      test('is used by GgProcessWrapper.run', () async {
        final delegate = _RecordingDelegate();
        GgProcessDelegate.current = delegate;

        const wrapper = GgProcessWrapper();
        final result = await wrapper.run('git', [
          'status',
        ], workingDirectory: '/tmp');

        expect(result.stdout, 'recorded-stdout');
        expect(delegate.calls, ['run git status @/tmp']);
      });

      test('is used by GgProcessWrapper.start', () async {
        final delegate = _RecordingDelegate();
        GgProcessDelegate.current = delegate;

        const wrapper = GgProcessWrapper();
        final process = await wrapper.start('git', ['log']);

        expect(await process.exitCode, 0);
        expect(delegate.calls, ['start git log']);
      });
    });

    // #########################################################################
    group('ggRunProcess', () {
      test('delegates to the current delegate', () async {
        final delegate = _RecordingDelegate();
        GgProcessDelegate.current = delegate;

        final result = await ggRunProcess('ls', [
          '-la',
        ], workingDirectory: '/x');
        expect(result.stdout, 'recorded-stdout');
        expect(delegate.calls, ['run ls -la @/x']);
      });

      test('runs the real process when no delegate is installed', () async {
        final result = await ggRunProcess('echo', ['Hello World']);
        expect(result.exitCode, 0);
        expect(result.stdout, contains('Hello World'));
      });

      test('matches the GgRunProcess signature', () async {
        const GgRunProcess runner = ggRunProcess;
        final result = await runner('echo', ['Hi']);
        expect(result.exitCode, 0);
      });
    });

    // #########################################################################
    group('ggStartProcess', () {
      test('delegates to the current delegate', () async {
        final delegate = _RecordingDelegate();
        GgProcessDelegate.current = delegate;

        final process = await ggStartProcess('ls', ['-la']);
        expect(await process.exitCode, 0);
        expect(delegate.calls, ['start ls -la']);
      });

      test('starts the real process when no delegate is installed', () async {
        final process = await ggStartProcess('echo', ['Hello World']);
        expect(await process.exitCode, 0);
      });
    });
  });
}
