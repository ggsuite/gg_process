// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

/// A wrapper around process, to allow mocking
class GgProcessMock implements Process {
  /// Default constructor
  GgProcessMock();

  /// Use this to define messages appearing at stdout
  void exit(int exitCode) {
    if (!pushToStdout.isClosed) {
      pushToStdout.close();
    }

    if (!pushToStderr.isClosed) {
      pushToStderr.close();
    }

    if ((!_exitCompleter.isCompleted)) {
      _exitCompleter.complete(exitCode);
    }
  }

  /// Use this to define messages appearing at stderr
  final pushToStderr = StreamController<String>.broadcast(sync: true);

  /// Use this to define messages appearing at stdout
  final pushToStdout = StreamController<String>.broadcast(sync: true);

  @override
  Future<int> get exitCode => _exitCompleter.future;
  @override
  Stream<List<int>> get stdout => pushToStdout.stream.map(
        (event) => event.codeUnits,
      );
  @override
  Stream<List<int>> get stderr => pushToStderr.stream.map(
        (event) => event.codeUnits,
      );

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  int get pid => 0;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    exit(-9);
    return true;
  }

  final _exitCompleter = Completer<int>();
}
