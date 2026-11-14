// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'gg_process_scope.dart';
import 'gg_windows_executable.dart';

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
/// builds use. On Windows it starts batch files such as `flutter` by their
/// full path, see [GgWindowsExecutable].
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
    _executable(executable, runInShell),
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
    _executable(executable, runInShell),
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

  // ######################
  // Private
  // ######################

  // ...........................................................................

  static final _windowsExecutable = GgWindowsExecutable();

  // ...........................................................................
  /// A shell finds batch files itself; without one, run them by full path.
  String _executable(String executable, bool runInShell) =>
      runInShell ? executable : _windowsExecutable.resolve(executable);
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
///
/// Inside a cancelled [GgProcessScope] nothing is run and a
/// [GgProcessCancelled] is thrown.
Future<ProcessResult> ggRunProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  Encoding? stdoutEncoding = systemEncoding,
  Encoding? stderrEncoding = systemEncoding,
}) async {
  GgProcessScope.current?.throwIfCancelled(executable, arguments);

  return GgProcessDelegate.current.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    stdoutEncoding: stdoutEncoding,
    stderrEncoding: stderrEncoding,
  );
}

// .............................................................................
/// Drop-in replacement for `Process.start` routing through
/// [GgProcessDelegate.current].
///
/// Inside a [GgProcessScope] the process is killed when the scope is
/// cancelled; inside a cancelled one nothing is started and a
/// [GgProcessCancelled] is thrown.
Future<Process> ggStartProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final scope = GgProcessScope.current;
  scope?.throwIfCancelled(executable, arguments);

  final process = await GgProcessDelegate.current.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );

  // A detached process has no exit code to wait for, and it is meant to
  // outlive whoever started it.
  if (mode == ProcessStartMode.normal ||
      mode == ProcessStartMode.inheritStdio) {
    scope?.track(process, workingDirectory: workingDirectory);
  }

  return process;
}
