// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'gg_platform_delegate.dart';
import 'gg_process_delegate.dart';

/// Thrown instead of starting a process in a cancelled [GgProcessScope].
class GgProcessCancelled implements Exception {
  /// Constructor. [command] is the command line that was not started.
  const GgProcessCancelled(this.command);

  /// The command line that was not started.
  final String command;

  @override
  String toString() => 'Cancelled before running "$command".';
}

/// Groups the processes a piece of code starts, so they can be stopped
/// together.
///
/// Code that runs several jobs side by side wants the others to stop as soon
/// as one of them fails. A job cannot be interrupted from outside, but the
/// processes it waits for can: run the job in a scope with [run], and
/// [cancel] ends the processes it started and refuses every further one —
/// the job then fails with a [GgProcessCancelled] at its next process and
/// unwinds by itself.
///
/// Only a process started with `ggStartProcess` is killed: these are the
/// long running ones, a test run for example. A process run with
/// `ggRunProcess` is left to finish — these are the short commands, git
/// above all, and interrupting one leaves a lock file or a half written
/// file behind.
///
/// A scope covers everything [run] starts, also asynchronously and in nested
/// calls: it travels with the [Zone]. Scopes nest — a process belongs to the
/// innermost one, and cancelling a scope cancels the scopes created inside.
/// [shield] takes a piece of code out of the scopes around it.
///
/// A killed process cannot clean up, and neither can the processes it
/// started. `beforeKill` is the chance to wait for a moment in which that
/// does no harm: it gets the working directory of the process about to be
/// killed, and the process is killed once it completes — also when it
/// throws. Without one a scope asks the scope around it.
class GgProcessScope {
  /// Constructor. The scope becomes a child of [current], if there is one.
  GgProcessScope({this._beforeKill}) : _parent = current {
    _parent?._children.add(this);
  }

  // ...........................................................................
  /// The scope the calling code runs in, or null when it runs in none.
  static GgProcessScope? get current =>
      Zone.current[_zoneKey] as GgProcessScope?;

  // ...........................................................................
  /// Runs [body] in this scope and returns its result.
  R run<R>(R Function() body) => runZoned(body, zoneValues: {_zoneKey: this});

  // ...........................................................................
  /// Runs [body] outside of every scope and returns its result: its
  /// processes are neither refused nor killed.
  ///
  /// For the steps that must not stop half way once they began, writing a
  /// file and committing it for example.
  static R shield<R>(R Function() body) =>
      runZoned(body, zoneValues: {_zoneKey: null});

  // ...........................................................................
  /// True once [cancel] was called on this scope or on one around it.
  bool get isCancelled => _isCancelled || (_parent?.isCancelled ?? false);

  // ...........................................................................
  /// Kills the processes started in this scope that still run and makes
  /// every further process fail with a [GgProcessCancelled].
  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;

    for (final MapEntry(key: process, value: workingDirectory)
        in _started.entries.toList()) {
      _kill(process, workingDirectory);
    }
    for (final child in _children.toList()) {
      child.cancel();
    }
  }

  // ...........................................................................
  /// Throws a [GgProcessCancelled] when the scope was cancelled.
  ///
  /// Called before a process is started; [executable] and [arguments] name
  /// it in the exception.
  void throwIfCancelled(String executable, List<String> arguments) {
    if (isCancelled) {
      throw GgProcessCancelled([executable, ...arguments].join(' '));
    }
  }

  // ...........................................................................
  /// Makes [cancel] kill [process], a process that was just started in
  /// [workingDirectory].
  ///
  /// A scope cancelled while the process was starting kills it right away.
  void track(Process process, {String? workingDirectory}) {
    if (isCancelled) {
      _kill(process, workingDirectory);
      return;
    }

    _started[process] = workingDirectory;
    process.exitCode
        .whenComplete(() => _started.remove(process))
        // The exit code is the caller's business, also when reading it
        // fails.
        .ignore();
  }

  // ######################
  // Private
  // ######################

  static final Object _zoneKey = Object();

  final GgProcessScope? _parent;
  final List<GgProcessScope> _children = [];

  /// The processes started in this scope that still run, with their working
  /// directory.
  final Map<Process, String?> _started = {};
  bool _isCancelled = false;

  final Future<void> Function(String? workingDirectory)? _beforeKill;

  // ...........................................................................
  /// What to wait for before a process of this scope is killed.
  Future<void> Function(String? workingDirectory)? get _waitBeforeKill =>
      _beforeKill ?? _parent?._waitBeforeKill;

  // ...........................................................................
  /// Kills [process], right away or once `beforeKill` is through.
  void _kill(Process process, String? workingDirectory) {
    final beforeKill = _waitBeforeKill;
    if (beforeKill == null) {
      _killNow(process);
      return;
    }

    Future.sync(() => beforeKill(workingDirectory))
        // Whatever became of the wait, the process must not go on.
        .then((_) => null, onError: (Object _) => null)
        .whenComplete(() => _killNow(process));
  }

  // ...........................................................................
  /// Ends [process] together with the processes it started.
  ///
  /// On Windows killing a process leaves its children running, and a test
  /// run is a launcher that starts the real work as a child. `taskkill /T`
  /// ends the whole tree. It is run outside the scope, which refuses
  /// processes by now.
  void _killNow(Process process) {
    if (!ggPlatform.isWindows) {
      process.kill();
      return;
    }

    GgProcessDelegate.current
        .run('taskkill', ['/PID', '${process.pid}', '/T', '/F'])
        // No taskkill, or the process is gone already: end what is left.
        .then((result) => result.exitCode == 0 ? true : process.kill())
        .catchError((Object _) => process.kill());
  }
}
