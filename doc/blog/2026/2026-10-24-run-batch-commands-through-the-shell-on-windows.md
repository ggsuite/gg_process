<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Run batch commands through the shell on Windows

## Motivation

- `GgProcessWrapper` starts console programs for its callers and lets
  their tests mock them
- It has to start the same commands on Windows as on macOS and Linux
- The Flutter SDK puts `flutter` and its `dart` on the Windows PATH as
  `flutter.bat` and `dart.bat` only
- Without a shell, `dart:io` starts only `.exe` and `.com` files, so a call
  like `flutter pub get --offline` failed: Windows did not find the file
- Callers should not have to know which commands are batch files

## Strategy

- Decide per executable whether it needs the shell
- Make the decision inside `GgProcessWrapper`, so callers stay unchanged
- Look the command up on the PATH as Windows does: the first match wins
- Keep macOS and Linux unchanged
- Cache the answer, since a caller may start hundreds of processes
- Make the tests pass in a plain Windows shell, not only in Git Bash

## Implementation 1: needsShell

- New public function `needsShell(executable, {platform})` in
  `lib/src/gg_process_wrapper.dart`
- Off Windows it returns false
- A name ending in `.bat` or `.cmd`, in any case, returns true; any other
  extension returns false
- A name without extension is looked up in the folders of `PATH`; the
  variable name is matched case-insensitively, as Windows does
- In each folder, `.exe` and `.com` come first and return false; `.bat`
  and `.cmd` follow and return true
- An unknown command returns false and fails as before
- The platform comes from `GgPlatformDelegate`, so tests can fake Windows

## Implementation 2: GgProcessWrapper takes the shell

- `run` and `start` pass `runInShell: runInShell || needsShell(executable)`
- A caller that asks for the shell keeps it
- Every caller of the wrapper starts batch commands without a change of
  its own
- The README explains the behavior and names `needsShell`

## Implementation 3: Cache the PATH lookup

- The review found the PATH walk costly: up to four file lookups per
  folder, for every process started
- `needsShell` now keeps its answer per command and PATH
- Another PATH is looked up anew
- A test checks that the first answer holds for the same command and PATH

## Implementation 4: Tests on Windows

- `test/gg_needs_shell_test.dart` covers all branches with a fake
  `GgPlatformDelegate` and temporary PATH folders
- The existing tests started `echo`, which Windows has as a builtin of
  `cmd` only; they passed only in Git Bash, which ships an `echo.exe`
- New `test/echo.dart` provides `echoCommand` and `echoArgs`, which use
  `cmd /c echo` on Windows
- The tests of the delegate, the wrapper and the process use them

## Dependency updates

- dna_ggsuite ^1.0.0, up from ^0.2.0, regenerated guides, skills and
  CLAUDE.md:
  - the workflow skills are now `/gg`, `/gg-ticket`, `/gg-commit`,
    `/gg-push`, `/gg-review`, `/gg-publish` and `/gg-cleanup`
  - blog posts go to `doc/blog/<yyyy>` and describe this repo only
  - a new README guide comes with `scripts/check-readme.js`
  - the code guides ask for `example` constructors and drop the package
    prefix of type names
  - a hook keeps prompts in a project management repo, if one is set

## Result

- Batch commands like `flutter` and the Flutter SDK's `dart` start on
  Windows through `GgProcessWrapper`
- The checks of this repo pass on Windows

## Open Points

- `ggRunProcess`, `ggStartProcess` and `GgProcessDelegate` do not ask
  `needsShell`; callers that use them pass `runInShell` themselves
- The cache lives as long as the process: a batch file added later to the
  same PATH is not found
- Arguments of a command started through the shell pass through `cmd.exe`,
  which interprets characters like `^`, `&` and `%`
