// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

import 'gg_platform_delegate.dart';
import 'gg_process_delegate.dart';

/// A wrapper around process, to allow mocking
///
/// The actual execution is performed by [GgProcessDelegate.current], so an
/// embedder can redirect every process gg starts — see
/// [GgProcessDelegate].
class GgProcessWrapper {
  /// Default constructor
  const GgProcessWrapper();

  // ...........................................................................
  /// Runs a process
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) async {
    return GgProcessDelegate.current.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell || needsShell(executable),
      stdoutEncoding: stdoutEncoding ?? utf8,
      stderrEncoding: stderrEncoding ?? utf8,
    );
  }

  // ...........................................................................
  /// Sstart a process
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    return GgProcessDelegate.current.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell || needsShell(executable),
      mode: mode,
    );
  }
}

// .............................................................................
/// Whether [executable] must run through the shell: on Windows, a command
/// that the PATH holds as a batch file only, e.g. `flutter.bat`, does not
/// start without `cmd.exe`. A `.exe` or `.com` found first starts
/// directly, as an unknown command does, which then fails as before.
bool needsShell(String executable, {GgPlatformDelegate? platform}) {
  platform ??= GgPlatformDelegate.current;
  if (!platform.isWindows) return false;

  final lower = executable.toLowerCase();
  if (lower.endsWith('.bat') || lower.endsWith('.cmd')) return true;
  if (lower.contains('.') && !lower.startsWith('.')) return false;

  final path = _windowsVariable(platform.environment, 'PATH') ?? '';
  return _needsShellCache.putIfAbsent(
    '$lower\n$path',
    () => _isBatchOnPath(executable, path),
  );
}

/// What [needsShell] found per command and PATH: a gg check starts hundreds
/// of processes, and the PATH walk costs up to four file lookups per folder.
final _needsShellCache = <String, bool>{};

/// Whether the first folder of [path] that holds [executable] holds it as a
/// batch file.
bool _isBatchOnPath(String executable, String path) {
  for (final directory in path.split(';')) {
    if (directory.isEmpty) continue;
    for (final extension in const ['.exe', '.com']) {
      if (File('$directory/$executable$extension').existsSync()) {
        return false;
      }
    }
    for (final extension in const ['.bat', '.cmd']) {
      if (File('$directory/$executable$extension').existsSync()) {
        return true;
      }
    }
  }
  return false;
}

/// The variable [name] of [environment], whose names Windows does not case.
String? _windowsVariable(Map<String, String> environment, String name) {
  for (final entry in environment.entries) {
    if (entry.key.toUpperCase() == name) return entry.value;
  }
  return null;
}

// #############################################################################
/// A mock for [GgProcessWrapper]
class MockGgProcessWrapper extends Mock implements GgProcessWrapper {}
