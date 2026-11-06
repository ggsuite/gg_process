<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Prefer the executable next to the running one

## Motivation

- Since 1.4.0, `GgProcessDelegate` starts batch files such as `flutter` by
  their full path on Windows, so they run without a shell.
- The lookup searched `PATH` only. Windows itself looks into the folder of
  the running executable first, and finds `dart.exe` there when a Dart
  program starts `dart`.
- Flutter puts a `dart.bat` wrapper on `PATH`. The lookup picked that
  wrapper instead of the `dart.exe` Windows would have started.
- The wrapper is much slower to start. Tools that run nested `dart test`
  processes ran into their timeouts.

## Strategy

- Keep every name Windows would start without help unchanged.
- Check the folder of the running executable before searching `PATH`, the
  way `CreateProcess` does.
- Read that folder through `GgPlatformDelegate`, so tests can fake it.

## Folder of the running executable

- `GgWindowsExecutable.resolve` keeps a bare name when the folder of
  `Platform.resolvedExecutable` holds it as `.exe` or `.com`.
- Only otherwise it looks for a `.bat` or `.cmd` file on `PATH`.
- `flutter`, `npm` and `pnpm` still resolve to their batch files: they have
  no `.exe` next to `dart.exe`.

## GgPlatformDelegate.resolvedExecutable

- New getter that returns `Platform.resolvedExecutable`.
- Hosts without `dart:io` can override it like the other getters.

## Result

- `dart` started from a Dart program is the same `dart.exe` again, as
  before 1.4.0.
- Nested `dart test` runs are as fast as they were before.

## Open Points

- Windows also searches the current folder and the system folders before
  `PATH`. The lookup does not: `PATH` usually holds the system folders, and
  a batch file there is found either way.
