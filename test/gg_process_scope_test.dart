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

// .............................................................................
/// Hands out fake processes and records the commands it is asked to run.
class _FakeDelegate extends GgProcessDelegate {
  _FakeDelegate({this.taskkillExitCode = 0, this.taskkillThrows = false});

  final int taskkillExitCode;
  final bool taskkillThrows;

  final List<String> runs = [];
  final List<_FakeProcess> started = [];

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
    runs.add([executable, ...arguments].join(' '));
    if (taskkillThrows) {
      throw const ProcessException('taskkill', []);
    }
    return ProcessResult(0, taskkillExitCode, '', '');
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
    final process = _FakeProcess(pid: 100 + started.length);
    started.add(process);
    return process;
  }
}

// .............................................................................
/// A fake process that counts how often it was killed.
class _FakeProcess extends GgFakeProcess {
  _FakeProcess({required this._pid});

  final int _pid;
  int kills = 0;

  @override
  int get pid => _pid;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    kills++;
    return super.kill(signal);
  }
}

// .............................................................................
/// A platform of the given operating system.
class _Platform extends GgPlatformDelegate {
  _Platform(this._os);

  final String _os;

  @override
  String get operatingSystem => _os;
}

void main() {
  late _FakeDelegate delegate;

  setUp(() {
    delegate = _FakeDelegate();
    GgProcessDelegate.current = delegate;
    GgPlatformDelegate.current = _Platform('linux');
  });

  tearDown(() {
    GgProcessDelegate.current = null;
    GgPlatformDelegate.current = null;
  });

  group('GgProcessScope', () {
    // #########################################################################
    group('current', () {
      test('is null outside a scope', () {
        expect(GgProcessScope.current, isNull);
      });

      test('is the scope run() was called on', () {
        final scope = GgProcessScope();
        expect(scope.run(() => GgProcessScope.current), same(scope));
      });

      test('is still that scope after an asynchronous gap', () async {
        final scope = GgProcessScope();
        final current = await scope.run(() async {
          await Future<void>.delayed(Duration.zero);
          return GgProcessScope.current;
        });
        expect(current, same(scope));
      });

      test('is the innermost scope', () {
        final outer = GgProcessScope();
        final inner = outer.run(GgProcessScope.new);
        final current = outer.run(
          () => inner.run(() => GgProcessScope.current),
        );
        expect(current, same(inner));
      });
    });

    // #########################################################################
    group('cancel()', () {
      test('refuses the next process', () async {
        final scope = GgProcessScope();
        scope.cancel();

        expect(scope.isCancelled, isTrue);
        await expectLater(
          scope.run(() => ggRunProcess('git', ['status'])),
          throwsA(
            isA<GgProcessCancelled>()
                .having((e) => e.command, 'command', 'git status')
                .having(
                  (e) => e.toString(),
                  'toString',
                  'Cancelled before running "git status".',
                ),
          ),
        );
        await expectLater(
          scope.run(() => ggStartProcess('dart', ['test'])),
          throwsA(isA<GgProcessCancelled>()),
        );
        await expectLater(
          scope.run(() => const GgProcessWrapper().run('git', ['status'])),
          throwsA(isA<GgProcessCancelled>()),
        );
        await expectLater(
          scope.run(() => const GgProcessWrapper().start('dart', ['test'])),
          throwsA(isA<GgProcessCancelled>()),
        );

        expect(delegate.runs, isEmpty);
        expect(delegate.started, isEmpty);
      });

      test('leaves the processes outside the scope alone', () async {
        final scope = GgProcessScope();
        scope.cancel();

        await ggRunProcess('git', ['status']);
        final process = await ggStartProcess('dart', ['test']);

        expect(delegate.runs, ['git status']);
        expect((process as _FakeProcess).kills, 0);
      });

      test('kills the processes started in the scope', () async {
        final scope = GgProcessScope();
        final first = await scope.run(() => ggStartProcess('dart', ['test']));
        final second = await scope.run(
          () => const GgProcessWrapper().start('dart', ['test']),
        );

        scope.cancel();

        expect((first as _FakeProcess).kills, 1);
        expect((second as _FakeProcess).kills, 1);
        expect(await first.exitCode, isNot(0));
      });

      test('kills each process only once', () async {
        final scope = GgProcessScope();
        final process = await scope.run(() => ggStartProcess('dart', ['test']));

        scope.cancel();
        scope.cancel();

        expect((process as _FakeProcess).kills, 1);
      });

      test('does not kill a process that ended before', () async {
        final scope = GgProcessScope();
        final process = await scope.run(() => ggStartProcess('dart', ['test']));
        (process as _FakeProcess).exit(0);
        await process.exitCode;
        await Future<void>.delayed(Duration.zero);

        scope.cancel();

        expect(process.kills, 0);
      });

      test('does not kill a detached process', () async {
        final scope = GgProcessScope();
        final process = await scope.run(
          () => ggStartProcess('code', ['.'], mode: ProcessStartMode.detached),
        );

        scope.cancel();

        expect((process as _FakeProcess).kills, 0);
      });

      test('kills a process that was starting meanwhile', () async {
        final scope = GgProcessScope();
        final starting = scope.run(() => ggStartProcess('dart', ['test']));
        scope.cancel();

        final process = await starting;
        expect((process as _FakeProcess).kills, 1);
      });

      test('cancels the scopes created inside', () async {
        final outer = GgProcessScope();
        final inner = outer.run(GgProcessScope.new);
        final process = await inner.run(() => ggStartProcess('dart', ['test']));

        outer.cancel();

        expect(inner.isCancelled, isTrue);
        expect((process as _FakeProcess).kills, 1);
      });

      test('reaches a scope created inside after the cancel', () {
        final outer = GgProcessScope();
        outer.cancel();

        final inner = outer.run(GgProcessScope.new);
        expect(inner.isCancelled, isTrue);
      });

      test('of an inner scope leaves the outer one running', () async {
        final outer = GgProcessScope();
        final inner = outer.run(GgProcessScope.new);
        final process = await outer.run(() => ggStartProcess('dart', ['test']));

        inner.cancel();

        expect(outer.isCancelled, isFalse);
        expect((process as _FakeProcess).kills, 0);
      });

      test('ignores a process whose exit code cannot be read', () async {
        final scope = GgProcessScope();
        final process = await scope.run(() => ggStartProcess('dart', ['test']));
        (process as _FakeProcess).exitWithException(Exception('gone'));
        await expectLater(process.exitCode, throwsException);

        scope.cancel();

        expect(process.kills, 0);
      });

      group('on Windows', () {
        setUp(() => GgPlatformDelegate.current = _Platform('windows'));

        test('ends the process together with its children', () async {
          final scope = GgProcessScope();
          final process = await scope.run(
            () => ggStartProcess('dart', ['test']),
          );

          scope.cancel();
          await Future<void>.delayed(Duration.zero);

          expect(delegate.runs, ['taskkill /PID 100 /T /F']);
          expect((process as _FakeProcess).kills, 0);
        });

        test('kills the process itself when taskkill fails', () async {
          delegate = _FakeDelegate(taskkillExitCode: 128);
          GgProcessDelegate.current = delegate;
          final scope = GgProcessScope();
          final process = await scope.run(
            () => ggStartProcess('dart', ['test']),
          );

          scope.cancel();
          await Future<void>.delayed(Duration.zero);

          expect((process as _FakeProcess).kills, 1);
        });

        test('kills the process itself when taskkill is missing', () async {
          delegate = _FakeDelegate(taskkillThrows: true);
          GgProcessDelegate.current = delegate;
          final scope = GgProcessScope();
          final process = await scope.run(
            () => ggStartProcess('dart', ['test']),
          );

          scope.cancel();
          await Future<void>.delayed(Duration.zero);

          expect((process as _FakeProcess).kills, 1);
        });
      });
    });

    // #########################################################################
    group('beforeKill', () {
      test('is waited for before a process is killed, and gets its working '
          'directory', () async {
        final mayKill = Completer<void>();
        final directories = <String?>[];
        final scope = GgProcessScope(
          beforeKill: (workingDirectory) {
            directories.add(workingDirectory);
            return mayKill.future;
          },
        );
        final process = await scope.run(
          () => ggStartProcess('dart', ['test'], workingDirectory: 'repo'),
        );

        scope.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(directories, ['repo']);
        expect((process as _FakeProcess).kills, 0);

        mayKill.complete();
        await Future<void>.delayed(Duration.zero);
        expect(process.kills, 1);
      });

      test('kills the process also when it throws', () async {
        final scope = GgProcessScope(
          beforeKill: (_) => throw StateError('cannot wait'),
        );
        final process = await scope.run(() => ggStartProcess('dart', ['test']));

        scope.cancel();
        await Future<void>.delayed(Duration.zero);

        expect((process as _FakeProcess).kills, 1);
      });

      test('of the scope around is used by a scope without one', () async {
        final asked = <String?>[];
        final outer = GgProcessScope(
          beforeKill: (workingDirectory) async => asked.add(workingDirectory),
        );
        final inner = outer.run(GgProcessScope.new);
        final process = await inner.run(
          () => ggStartProcess('dart', ['test'], workingDirectory: 'inner'),
        );

        outer.cancel();
        await Future<void>.delayed(Duration.zero);

        expect(asked, ['inner']);
        expect((process as _FakeProcess).kills, 1);
      });

      test('is asked as well for a process that was starting '
          'meanwhile', () async {
        final asked = <String?>[];
        final scope = GgProcessScope(
          beforeKill: (workingDirectory) async => asked.add(workingDirectory),
        );
        final starting = scope.run(
          () => ggStartProcess('dart', ['test'], workingDirectory: 'late'),
        );
        scope.cancel();

        final process = await starting;
        await Future<void>.delayed(Duration.zero);

        expect(asked, ['late']);
        expect((process as _FakeProcess).kills, 1);
      });
    });

    // #########################################################################
    group('shield()', () {
      test('runs the body outside of the scope', () {
        final scope = GgProcessScope();
        final current = scope.run(
          () => GgProcessScope.shield(() => GgProcessScope.current),
        );
        expect(current, isNull);
      });

      test('keeps running processes in a cancelled scope', () async {
        final scope = GgProcessScope();
        scope.cancel();

        final process = await scope.run(
          () => GgProcessScope.shield(() async {
            await ggRunProcess('git', ['commit']);
            return ggStartProcess('dart', ['test']);
          }),
        );

        expect(delegate.runs, ['git commit']);
        expect((process as _FakeProcess).kills, 0);
      });

      test('does not let a later cancel kill its processes', () async {
        final scope = GgProcessScope();
        final process = await scope.run(
          () => GgProcessScope.shield(() => ggStartProcess('dart', ['test'])),
        );

        scope.cancel();

        expect((process as _FakeProcess).kills, 0);
      });
    });

    // #########################################################################
    group('with real processes', () {
      setUp(() {
        GgProcessDelegate.current = null;
        GgPlatformDelegate.current = null;
      });

      test('ends a running process', () async {
        final tmp = Directory.systemTemp.createTempSync('gg_process_scope');
        addTearDown(() => tmp.deleteSync(recursive: true));
        final script = File('${tmp.path}/wait.dart')
          ..writeAsStringSync(
            'Future<void> main() => '
            'Future<void>.delayed(const Duration(minutes: 5));',
          );

        final scope = GgProcessScope();
        final process = await scope.run(
          () => ggStartProcess(Platform.resolvedExecutable, [script.path]),
        );

        final stopwatch = Stopwatch()..start();
        scope.cancel();
        final exitCode = await process.exitCode;

        expect(exitCode, isNot(0));
        expect(stopwatch.elapsed, lessThan(const Duration(minutes: 1)));
      });
    });
  });
}
