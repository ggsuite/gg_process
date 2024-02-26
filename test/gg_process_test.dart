// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:gg_process/gg_process.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];

  group('GgProcess()', () {
    // #########################################################################
    group('exec()', () {
      test('description of the test ', () async {
        final ggProcess =
            GgProcess(param: 'foo', log: (msg) => messages.add(msg));

        await ggProcess.exec();
      });
    });

    // #########################################################################
    group('Command', () {
      test('should allow to run the code from command line', () async {
        final ggProcess = GgProcessCmd(log: (msg) => messages.add(msg));

        final CommandRunner<void> runner = CommandRunner<void>(
          'ggProcess',
          'Description goes here.',
        )..addCommand(ggProcess);

        await runner.run(['ggProcess', '--param', 'foo']);
      });
    });
  });
}
