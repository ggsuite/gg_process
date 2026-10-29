// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_process/gg_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// .............................................................................
/// Reports the given operating system and environment.
class _FakePlatform extends GgPlatformDelegate {
  _FakePlatform(this.environment, {this.operatingSystem = 'windows'});

  @override
  final Map<String, String> environment;

  @override
  final String operatingSystem;
}

void main() {
  late Directory tempDir;
  late String first;
  late String second;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gg_windows_executable_');
    first = (Directory(p.join(tempDir.path, 'first'))..createSync()).path;
    second = (Directory(p.join(tempDir.path, 'second'))..createSync()).path;
  });

  tearDown(() {
    GgPlatformDelegate.current = null;
    tempDir.deleteSync(recursive: true);
  });

  // ...........................................................................
  void touch(String directory, String file) =>
      File(p.join(directory, file)).writeAsStringSync('');

  // ...........................................................................
  GgWindowsExecutable resolver({
    String? path,
    String? pathExt,
    String operatingSystem = 'windows',
  }) => GgWindowsExecutable.example(
    platform: _FakePlatform({
      'Path': path ?? '$first;$second',
      'PATHEXT': ?pathExt,
    }, operatingSystem: operatingSystem),
  );

  group('GgWindowsExecutable', () {
    group('resolve()', () {
      test('returns the full path of a batch file on PATH', () {
        touch(second, 'flutter.bat');
        touch(second, 'npm.cmd');

        final windowsExecutable = resolver();

        expect(
          windowsExecutable.resolve('flutter'),
          p.join(second, 'flutter.bat'),
        );
        expect(windowsExecutable.resolve('npm'), p.join(second, 'npm.cmd'));
      });

      test('keeps a name Windows starts itself', () {
        touch(first, 'git.exe');
        touch(second, 'git.bat');
        touch(first, 'more.com');

        final windowsExecutable = resolver();

        expect(windowsExecutable.resolve('git'), 'git');
        expect(windowsExecutable.resolve('more'), 'more');
      });

      test('keeps a name that is not on PATH', () {
        expect(resolver().resolve('unknown'), 'unknown');
      });

      test('keeps paths and names with an extension', () {
        touch(first, 'flutter.bat');
        final windowsExecutable = resolver();

        expect(windowsExecutable.resolve('flutter.bat'), 'flutter.bat');
        expect(windowsExecutable.resolve('bin/flutter'), 'bin/flutter');
        expect(windowsExecutable.resolve(r'bin\flutter'), r'bin\flutter');
      });

      test('keeps every name outside of Windows', () {
        touch(first, 'flutter.bat');

        expect(
          resolver(operatingSystem: 'linux').resolve('flutter'),
          'flutter',
        );
      });

      test('follows the order of PATHEXT', () {
        touch(first, 'tool.exe');
        touch(first, 'tool.bat');

        expect(
          resolver(pathExt: '.BAT;.EXE').resolve('tool'),
          p.join(first, 'tool.bat'),
        );
      });

      test('skips empty and quoted PATH entries', () {
        touch(second, 'flutter.bat');

        expect(
          resolver(path: ';"$second";').resolve('flutter'),
          p.join(second, 'flutter.bat'),
        );
      });

      test('finds nothing without PATH', () {
        touch(first, 'flutter.bat');
        final windowsExecutable = GgWindowsExecutable.example(
          platform: _FakePlatform({}),
        );

        expect(windowsExecutable.resolve('flutter'), 'flutter');
      });

      test('remembers what it resolved', () {
        touch(first, 'flutter.bat');
        final windowsExecutable = resolver();

        expect(
          windowsExecutable.resolve('flutter'),
          p.join(first, 'flutter.bat'),
        );
        File(p.join(first, 'flutter.bat')).deleteSync();
        expect(
          windowsExecutable.resolve('flutter'),
          p.join(first, 'flutter.bat'),
        );
      });

      test('reads GgPlatformDelegate.current by default', () {
        touch(first, 'flutter.bat');
        GgPlatformDelegate.current = _FakePlatform({'PATH': first});

        expect(
          GgWindowsExecutable().resolve('flutter'),
          p.join(first, 'flutter.bat'),
        );
      });
    });

    group('GgProcessDelegate', () {
      test('runs a batch file by its bare name', () async {
        File(p.join(first, 'gg_probe.bat'))
            .writeAsStringSync('@echo off\r\necho probe %1\r\nexit /b 3\r\n');
        GgPlatformDelegate.current = _FakePlatform({'PATH': first});

        const delegate = GgProcessDelegate.defaultDelegate;
        final result = await delegate.run('gg_probe', ['one']);
        expect(result.exitCode, 3);
        expect(result.stdout.toString().trim(), 'probe one');

        final process = await delegate.start('gg_probe', ['two']);
        expect(await process.exitCode, 3);
      }, skip: Platform.isWindows ? false : 'Windows only');
    });
  });
}
