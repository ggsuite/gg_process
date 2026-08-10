// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io' as io;

import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

// .............................................................................
/// Answers everything from memory instead of asking `dart:io`.
class _FakePlatform extends GgPlatformDelegate {
  _FakePlatform(this._os);

  final String _os;
  int recordedExitCode = -1;

  @override
  Map<String, String> get environment => const {'GG_TEST': 'yes'};

  @override
  String get operatingSystem => _os;

  @override
  String get pathSeparator => _os == 'windows' ? r'\' : '/';

  @override
  int get exitCode => recordedExitCode;

  @override
  set exitCode(int value) => recordedExitCode = value;
}

void main() {
  tearDown(() => GgPlatformDelegate.current = null);

  group('GgPlatformDelegate', () {
    // #########################################################################
    group('defaultDelegate', () {
      test('reads dart:io', () {
        const delegate = GgPlatformDelegate.defaultDelegate;
        expect(delegate.environment, io.Platform.environment);
        expect(delegate.operatingSystem, io.Platform.operatingSystem);
        expect(delegate.pathSeparator, io.Platform.pathSeparator);
        expect(delegate.isWindows, io.Platform.isWindows);
        expect(delegate.isMacOS, io.Platform.isMacOS);
        expect(delegate.isLinux, io.Platform.isLinux);
      });

      test('reads and writes the process exit code', () {
        const delegate = GgPlatformDelegate.defaultDelegate;
        final before = delegate.exitCode;
        addTearDown(() => delegate.exitCode = before);

        delegate.exitCode = 0;
        expect(delegate.exitCode, 0);
        expect(io.exitCode, 0);
      });

      test('is installed by default', () {
        expect(GgPlatformDelegate.current, GgPlatformDelegate.defaultDelegate);
      });
    });

    // #########################################################################
    group('current', () {
      test('can be replaced and reset', () {
        final delegate = _FakePlatform('linux');
        GgPlatformDelegate.current = delegate;
        expect(GgPlatformDelegate.current, delegate);
        expect(ggPlatform, delegate);

        GgPlatformDelegate.current = null;
        expect(GgPlatformDelegate.current, GgPlatformDelegate.defaultDelegate);
      });

      test('answers the os questions from the replacement', () {
        GgPlatformDelegate.current = _FakePlatform('windows');
        expect(ggPlatform.isWindows, isTrue);
        expect(ggPlatform.isMacOS, isFalse);
        expect(ggPlatform.isLinux, isFalse);
        expect(ggPlatform.pathSeparator, r'\');
        expect(ggPlatform.environment, {'GG_TEST': 'yes'});

        GgPlatformDelegate.current = _FakePlatform('macos');
        expect(ggPlatform.isMacOS, isTrue);

        GgPlatformDelegate.current = _FakePlatform('linux');
        expect(ggPlatform.isLinux, isTrue);
      });
    });

    // #########################################################################
    group('ggExitCode', () {
      test('routes through the current delegate', () {
        final delegate = _FakePlatform('linux');
        GgPlatformDelegate.current = delegate;

        ggExitCode = 42;
        expect(delegate.recordedExitCode, 42);
        expect(ggExitCode, 42);
      });
    });
  });
}
