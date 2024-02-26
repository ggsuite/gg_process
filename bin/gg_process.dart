#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:colorize/colorize.dart';
import 'package:gg_process/gg_process.dart';

// .............................................................................
Future<void> runGgProcess({
  required List<String> args,
  required void Function(String msg) log,
}) async {
  try {
    // Create a command runner
    final CommandRunner<void> runner = CommandRunner<void>(
      'GgProcess',
      'GgProcess is a wrapper around Process. '
          'run and Process. '
          'start. '
          'It allows us to mock the execution of console programs. ',
    )..addCommand(GgProcessCmd(log: log));

    // Run the command
    await runner.run(args);
  }

  // Print errors in red
  catch (e) {
    final msg = e.toString().replaceAll('Exception: ', '');
    log(Colorize(msg).red().toString());
    log('Error: $e');
  }
}

// .............................................................................
Future<void> main(List<String> args) async {
  await runGgProcess(
    args: args,
    log: (msg) => print(msg),
  );
}
