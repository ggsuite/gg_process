// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';

/// A mock for [IOSink]
class MockIOSink extends Mock implements IOSink {}

/// A wrapper around process, to allow mocking
class GgFakeProcess implements Process {
  /// Default constructor
  GgFakeProcess();

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

  /// Exit with an exception
  void exitWithException(Object excpetion) {
    if (!pushToStdout.isClosed) {
      pushToStdout.close();
    }

    if (!pushToStderr.isClosed) {
      pushToStderr.close();
    }

    if ((!_exitCompleter.isCompleted)) {
      _exitCompleter.completeError(excpetion);
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
  MockIOSink get stdin => _stdInSink;

  @override
  int get pid => 0;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    exit(-9);
    return true;
  }

  final _exitCompleter = Completer<int>();
  final _stdInSink = MockIOSink();
}
