# gg_process

GgProcess is a wrapper around Process.run and Process.start. It allows us to mock the execution of console programs.

On Windows, `run` and `start` take the shell for a command the PATH holds
as a batch file only, e.g. `flutter.bat` or the `dart.bat` of the Flutter
SDK, which `dart:io` would not find otherwise. `needsShell(executable)`
tells which commands those are.
