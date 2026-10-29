// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

import 'gg_platform_delegate.dart';

/// Finds the batch file behind a bare command name on Windows. Windows
/// starts a bare name only as `.exe` or `.com`, so tools shipped as `.bat`
/// or `.cmd` — `flutter`, `npm`, `pnpm` — fail unless run in a shell.
class GgWindowsExecutable {
  /// Constructor. Reads [platform], or else [GgPlatformDelegate.current].
  GgWindowsExecutable({this._platform});

  // ...........................................................................
  /// The full path of the `.bat` or `.cmd` file a shell would run for
  /// [executable], or [executable] itself when Windows starts it without one.
  String resolve(String executable) {
    if (!_platformDelegate.isWindows || !_isBareName(executable)) {
      return executable;
    }

    return _resolved[executable] ??= _batchFile(executable) ?? executable;
  }

  /// An instance for tests.
  factory GgWindowsExecutable.example({GgPlatformDelegate? platform}) =>
      GgWindowsExecutable(platform: platform);

  // ######################
  // Private
  // ######################

  // ...........................................................................

  final GgPlatformDelegate? _platform;

  /// The resolved executables by name: PATH does not change while gg runs.
  final Map<String, String> _resolved = {};

  static const _batchExtensions = {'.bat', '.cmd'};

  // ...........................................................................
  GgPlatformDelegate get _platformDelegate =>
      _platform ?? GgPlatformDelegate.current;

  // ...........................................................................
  bool _isBareName(String executable) =>
      !executable.contains('/') &&
      !executable.contains(r'\') &&
      p.extension(executable).isEmpty;

  // ...........................................................................
  /// Searches PATH the way cmd does and returns the first match if it is a
  /// batch file.
  String? _batchFile(String name) {
    for (final directory in _pathDirectories) {
      for (final extension in _extensions) {
        final candidate = p.join(directory, '$name$extension');
        if (File(candidate).existsSync()) {
          return _batchExtensions.contains(extension) ? candidate : null;
        }
      }
    }

    return null;
  }

  // ...........................................................................
  Iterable<String> get _pathDirectories => (_variable('PATH') ?? '')
      .split(';')
      .map((directory) => directory.replaceAll('"', '').trim())
      .where((directory) => directory.isNotEmpty);

  // ...........................................................................
  Iterable<String> get _extensions =>
      (_variable('PATHEXT') ?? '.COM;.EXE;.BAT;.CMD')
          .toLowerCase()
          .split(';')
          .where((extension) => extension.isNotEmpty);

  // ...........................................................................
  /// Windows names environment variables case-insensitively, e.g. `Path`.
  String? _variable(String name) {
    for (final entry in _platformDelegate.environment.entries) {
      if (entry.key.toUpperCase() == name) {
        return entry.value;
      }
    }

    return null;
  }
}

/// Mock for [GgWindowsExecutable].
class MockGgWindowsExecutable extends Mock implements GgWindowsExecutable {}
