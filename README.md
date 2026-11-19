# gg_process

GgProcess is a wrapper around Process.run and Process.start. It allows us to mock the execution of console programs.

## Batch files on Windows

Windows starts a bare command name only as `.exe` or `.com`. Tools such as
`flutter`, `npm` or `pnpm` ship as `.bat` or `.cmd` files, so
`Process.run('flutter', …)` fails there unless `runInShell` is set.
`GgProcessDelegate` therefore looks such a name up on `PATH` the way cmd does
and starts the batch file by its full path. A name Windows finds as `.exe` or
`.com` first stays as it is — on `PATH`, or in the folder of the running
executable, which Windows searches before `PATH`. So `dart` started from
`dart.exe` stays that `dart.exe`, even when Flutter puts a `dart.bat` on
`PATH`.

## Cancelling a group of processes

`GgProcessScope` groups the processes a piece of code starts, so they can
be stopped together. `scope.run(...)` runs a job in the scope; the scope
travels with the zone, also into asynchronous and nested calls.
`scope.cancel()` kills the processes started with `ggStartProcess` that
still run and makes every further process fail with a
`GgProcessCancelled`. Processes run with `ggRunProcess` — the short ones,
git above all — are left to finish. `GgProcessScope.shield(...)` takes a
step out of the scopes around it, and `beforeKill` lets a scope wait for a
safe moment before a process is killed.

## A delegate for one piece of code

`GgProcessDelegate.runWith(delegate, body)` lets `delegate` execute the
processes `body` runs or starts — only those: like a `GgProcessScope`, the
choice travels with the zone, and code running at the same time keeps
`GgProcessDelegate.current`. A delegate that adds to what processes do
forwards to the one it replaces, read as `current` before the call. gg_git
watches every git network command this way while `GitRetry` runs it.

`ggPlatform.numberOfProcessors` tells how many processors the machine has;
a `GgPlatformDelegate` replaces it in tests.
