// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

/// A host with [operatingSystem] and the PATH [path].
class _Platform extends GgPlatformDelegate {
  const _Platform(this.operatingSystem, this.path);

  @override
  final String operatingSystem;

  final String path;

  @override
  Map<String, String> get environment => {'Path': path};
}

void main() {
  late Directory exeDir;
  late Directory batDir;

  setUp(() {
    exeDir = Directory.systemTemp.createTempSync('gg_needs_shell_exe');
    batDir = Directory.systemTemp.createTempSync('gg_needs_shell_bat');
    File('${batDir.path}/flutter.bat').writeAsStringSync('');
    File('${batDir.path}/tool.cmd').writeAsStringSync('');
    File('${batDir.path}/dart.bat').writeAsStringSync('');
    File('${exeDir.path}/dart.exe').writeAsStringSync('');
  });

  tearDown(() {
    exeDir.deleteSync(recursive: true);
    batDir.deleteSync(recursive: true);
  });

  group('needsShell(executable, platform)', () {
    test('is false off Windows', () {
      final linux = _Platform('linux', batDir.path);
      expect(needsShell('flutter', platform: linux), isFalse);
    });

    test('is true for a batch file on the PATH of Windows', () {
      final windows = _Platform('windows', ';${batDir.path}');
      expect(needsShell('flutter', platform: windows), isTrue);
      expect(needsShell('tool', platform: windows), isTrue);
    });

    test('is false when an executable comes first on the PATH', () {
      final windows = _Platform('windows', '${exeDir.path};${batDir.path}');
      expect(needsShell('dart', platform: windows), isFalse);
    });

    test('is true for a .bat or .cmd named with its extension', () {
      const windows = _Platform('windows', '');
      expect(needsShell('build.BAT', platform: windows), isTrue);
      expect(needsShell('build.cmd', platform: windows), isTrue);
    });

    test('is false for other extensions and unknown commands', () {
      final windows = _Platform('windows', batDir.path);
      expect(needsShell('git.exe', platform: windows), isFalse);
      expect(needsShell('unknown', platform: windows), isFalse);
    });

    test('looks the PATH up once per command and PATH', () {
      final windows = _Platform('windows', batDir.path);
      expect(needsShell('cached', platform: windows), isFalse);
      File('${batDir.path}/cached.bat').writeAsStringSync('');
      // The first answer holds for the same command and PATH.
      expect(needsShell('cached', platform: windows), isFalse);
      // Another PATH is looked up anew.
      final other = _Platform('windows', ';${batDir.path}');
      expect(needsShell('cached', platform: other), isTrue);
    });

    test('takes the current platform by default', () {
      expect(needsShell('unknown-command-of-gg'), isFalse);
    });
  });
}
