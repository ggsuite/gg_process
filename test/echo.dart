// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

/// The command that echoes; Windows has echo as a builtin of cmd only.
String get echoCommand => Platform.isWindows ? 'cmd' : 'echo';

/// The arguments of [echoCommand] that echo [words].
List<String> echoArgs(List<String> words) =>
    Platform.isWindows ? ['/c', 'echo', ...words] : words;
