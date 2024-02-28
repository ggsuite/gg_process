// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// #############################################################################
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:gg_process/gg_process.dart';

// #############################################################################
/// Creates a fake environment for running processes
class GgProcessMock implements GgProcess {
  /// Creates a fake process environment
  /// - [fakeResult] will be returned by [run]
  /// - [startFakeResult] will be returned by [start]
  GgProcessMock({
    ProcessResult? fakeResult,
    Process? startFakeResult,
  })  : _processResult = fakeResult ?? ProcessResult(0, 0, '', ''),
        _fakeProcess = startFakeResult;

  /// All calls of run
  final List<CallArguments> calls = [];

  /// The run function
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) {
    calls.add(
      CallArguments(
        executable: executable,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        includeParentEnvironment: includeParentEnvironment,
        runInShell: runInShell,
        stdoutEncoding: stdoutEncoding,
        stderrEncoding: stderrEncoding,
      ),
    );
    return Future.value(_processResult);
  }

  /// The start function
  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    assert(_fakeProcess != null, 'fakeProcess must be set');
    return Future.value(_fakeProcess!);
  }

  // ...........................................................................
  final ProcessResult _processResult;
  final Process? _fakeProcess;
}

// #############################################################################
/// The arguments forwarded to process.run
class CallArguments {
  /// Creates a new instance of CallArguments
  CallArguments({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
    required this.environment,
    required this.includeParentEnvironment,
    required this.runInShell,
    required this.stdoutEncoding,
    required this.stderrEncoding,
  });

  /// The executable
  final String executable;

  /// The arguments
  final List<String> arguments;

  /// The working directory
  final String? workingDirectory;

  /// The environment
  final Map<String, String>? environment;

  /// Include the parent environment
  final bool includeParentEnvironment;

  /// Run in shell
  final bool runInShell;

  /// The stdout encoding
  final Encoding? stdoutEncoding;

  /// The stderr encoding
  final Encoding? stderrEncoding;

  /// Returns true if the process should run in dry-run mode
  bool get dryRun => arguments.contains('--dry-run');

  static const DeepCollectionEquality _eq = DeepCollectionEquality();

  /// Compares two CallArguments
  @override
  bool operator ==(Object other) {
    if (other is CallArguments) {
      return executable == other.executable &&
          _eq.equals(arguments, other.arguments) &&
          workingDirectory == other.workingDirectory &&
          _eq.equals(environment, other.environment) &&
          includeParentEnvironment == other.includeParentEnvironment &&
          runInShell == other.runInShell &&
          stdoutEncoding == other.stdoutEncoding &&
          stderrEncoding == other.stderrEncoding;
    }
    return false;
  }

  /// The hash code
  @override
  int get hashCode {
    return executable.hashCode ^
        _eq.hash(arguments) ^
        workingDirectory.hashCode ^
        _eq.hash(environment) ^
        includeParentEnvironment.hashCode ^
        runInShell.hashCode ^
        stdoutEncoding.hashCode ^
        stderrEncoding.hashCode;
  }
}
