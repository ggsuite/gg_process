#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_process/gg_process.dart';

Future<void> main() async {
  const param = 'foo';

  final ggProcess = GgProcess(
    param: param,
    log: (msg) {},
  );

  print('Executing with param $param');
  await ggProcess.exec();

  print('Done.');
}
