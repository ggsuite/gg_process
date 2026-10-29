# gg_process

GgProcess is a wrapper around Process.run and Process.start. It allows us to mock the execution of console programs.

## Batch files on Windows

Windows starts a bare command name only as `.exe` or `.com`. Tools such as
`flutter`, `npm` or `pnpm` ship as `.bat` or `.cmd` files, so
`Process.run('flutter', …)` fails there unless `runInShell` is set.
`GgProcessDelegate` therefore looks such a name up on `PATH` the way cmd does
and starts the batch file by its full path. A name Windows finds as `.exe` or
`.com` first stays as it is.
