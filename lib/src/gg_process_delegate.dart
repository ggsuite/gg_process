// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

/// Performs the actual process execution for the whole gg suite.
///
/// `dart compile wasm` emits a `dart:io` whose `Process.run` and
/// `Process.start` throw `UnsupportedError` at runtime. Every gg package
/// therefore routes process execution through [GgProcessDelegate.current]
/// instead of calling `Process` directly. An embedder — for example the
/// `gg-js` npm package running gg as WebAssembly — replaces
/// [GgProcessDelegate.current] with an implementation backed by the host,
/// e.g. Node's `child_process`.
///
/// The default implementation calls `dart:io` and is what native `gg`
/// builds use.
class GgProcessDelegate {
  /// Default constructor
  const GgProcessDelegate();

  // ...........................................................................
  /// Runs [executable] with [arguments] and waits for it to complete.
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding,
  }) => Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );

  // ...........................................................................
  /// Starts [executable] with [arguments] and returns the running process.
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) => Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );

  // ...........................................................................
  /// The delegate the gg suite currently executes processes with.
  static GgProcessDelegate get current => _current;

  /// Replaces the delegate. Pass `null` to restore [defaultDelegate].
  static set current(GgProcessDelegate? delegate) =>
      _current = delegate ?? defaultDelegate;

  /// The `dart:io` backed delegate used unless [current] is replaced.
  static const GgProcessDelegate defaultDelegate = GgProcessDelegate();

  static GgProcessDelegate _current = defaultDelegate;
}

// .............................................................................
/// Signature of `Process.run`, used as an injection point in several gg
/// packages. Use [ggRunProcess] as default instead of `Process.run` so the
/// call is routed through [GgProcessDelegate.current].
typedef GgRunProcess = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment,
  bool runInShell,
  Encoding? stdoutEncoding,
  Encoding? stderrEncoding,
});

// .............................................................................
/// Drop-in replacement for `Process.run` routing through
/// [GgProcessDelegate.current].
Future<ProcessResult> ggRunProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
}) => GgProcessDelegate.current.run(
  executable,
  arguments,
  workingDirectory: workingDirectory,
  environment: environment,
  includeParentEnvironment: includeParentEnvironment,
  runInShell: runInShell,
  stdoutEncoding: stdoutEncoding,
  stderrEncoding: stderrEncoding,
);

// .............................................................................
/// Drop-in replacement for `Process.start` routing through
/// [GgProcessDelegate.current].
Future<Process> ggStartProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) => GgProcessDelegate.current.start(
  executable,
  arguments,
  workingDirectory: workingDirectory,
  environment: environment,
  includeParentEnvironment: includeParentEnvironment,
  runInShell: runInShell,
  mode: mode,
);
