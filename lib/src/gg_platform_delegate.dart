// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io' as io;

/// Answers questions about the process gg runs in and the machine hosting it.
///
/// `dart compile wasm` emits a `dart:io` whose `Platform` members and whose
/// `exitCode` setter throw `UnsupportedError` at runtime. Every gg package
/// therefore asks [GgPlatformDelegate.current] instead of `Platform`. An
/// embedder — for example the `gg-js` npm package running gg as
/// WebAssembly — replaces [GgPlatformDelegate.current] with an
/// implementation backed by the host, e.g. Node's `process.env` and
/// `process.platform`.
///
/// The default implementation reads `dart:io` and is what native `gg`
/// builds use.
class GgPlatformDelegate {
  /// Default constructor
  const GgPlatformDelegate();

  /// The environment variables of the current process.
  Map<String, String> get environment => io.Platform.environment;

  /// The operating system, e.g. `macos`, `linux` or `windows`.
  String get operatingSystem => io.Platform.operatingSystem;

  /// The character separating path segments, e.g. `/` or `\`.
  String get pathSeparator => io.Platform.pathSeparator;

  /// True on Windows.
  bool get isWindows => operatingSystem == 'windows';

  /// True on macOS.
  bool get isMacOS => operatingSystem == 'macos';

  /// True on Linux.
  bool get isLinux => operatingSystem == 'linux';

  /// The exit code the process will terminate with.
  int get exitCode => io.exitCode;

  /// Sets the exit code the process will terminate with.
  set exitCode(int value) => io.exitCode = value;

  // ...........................................................................
  /// The delegate the gg suite currently asks about its host.
  static GgPlatformDelegate get current => _current;

  /// Replaces the delegate. Pass `null` to restore [defaultDelegate].
  static set current(GgPlatformDelegate? delegate) =>
      _current = delegate ?? defaultDelegate;

  /// The `dart:io` backed delegate used unless [current] is replaced.
  static const GgPlatformDelegate defaultDelegate = GgPlatformDelegate();

  static GgPlatformDelegate _current = defaultDelegate;
}

// .............................................................................
/// Shorthand for [GgPlatformDelegate.current].
GgPlatformDelegate get ggPlatform => GgPlatformDelegate.current;

// .............................................................................
/// The exit code the gg process will terminate with, routed through
/// [GgPlatformDelegate.current]. Use instead of `dart:io`'s `exitCode`.
int get ggExitCode => GgPlatformDelegate.current.exitCode;

/// Sets the exit code the gg process will terminate with, routed through
/// [GgPlatformDelegate.current]. Use instead of `dart:io`'s `exitCode`.
set ggExitCode(int value) => GgPlatformDelegate.current.exitCode = value;
