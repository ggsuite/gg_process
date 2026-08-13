// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

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
      runInShell: runInShell,
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
      runInShell: runInShell,
      mode: mode,
    );
  }
}

// #############################################################################
/// A mock for [GgProcessWrapper]
class MockGgProcessWrapper extends Mock implements GgProcessWrapper {}
