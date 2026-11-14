<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Cancel a group of processes

## Motivation

- Code that runs several jobs side by side wants the others to stop as soon
  as one of them fails. Their results no longer count.
- A job cannot be interrupted from outside. The processes it waits for can.
- Until now there was no way to tell which running processes belong to
  which job, and so no way to stop them together.
- Every process of this package goes through `ggRunProcess` and
  `ggStartProcess`. That is the place to group them.

## Strategy

- One new class, `GgProcessScope`: run a job in it, cancel it from outside.
- Let the scope travel with the `Zone`, so no function needs a new
  parameter.
- Kill only the long running processes. Let the short ones finish.
- After a cancel, refuse every further process with an exception. The job
  then fails at its next process and unwinds by itself.
- Offer two ways out for steps that must not stop half way: `shield` and
  `beforeKill`.

## A scope that travels with the zone

- `scope.run(body)` runs `body` in the scope. Everything `body` starts
  belongs to it, also after an asynchronous gap and in nested calls.
- `GgProcessScope.current` is the scope of the calling code, or null.
- Scopes nest. A process belongs to the innermost scope, and cancelling a
  scope cancels the scopes created inside it. Cancelling an inner scope
  leaves the outer one running.
- `GgProcessWrapper` now calls `ggRunProcess` and `ggStartProcess`, so code
  that uses the wrapper is covered without a change.

## What cancel does

- `cancel()` kills the processes started with `ggStartProcess` that still
  run. These are the long running ones, a test run for example.
- A process run with `ggRunProcess` is left to finish. These are the short
  commands, and interrupting one leaves a lock file or a half written file
  behind.
- Every further process fails with `GgProcessCancelled`. The exception
  names the command line that was not started.
- A process that was starting while the scope was cancelled is killed right
  away. A detached process is never killed: it is meant to outlive whoever
  started it.
- On Windows, killing a process leaves its children running. The scope runs
  `taskkill /PID <pid> /T /F` to end the whole tree, and kills the process
  itself when taskkill fails or is missing.

## Steps that must not stop half way

- `GgProcessScope.shield(body)` runs `body` outside of every scope. Its
  processes are neither refused nor killed, also when a cancel comes later.
  It is meant for steps like writing a file and committing it.
- `GgProcessScope(beforeKill: …)` waits for a moment in which a kill does
  no harm. The callback gets the working directory of the process about to
  be killed.
- The process is killed once the callback completes, also when it throws.
- A scope without `beforeKill` asks the scope around it.

## Number of processors

- `GgPlatformDelegate.numberOfProcessors` tells how many things the machine
  can do at the same time.
- It answers 1 when the host cannot tell, a Wasm build for example.
- Code that runs jobs side by side can size its work with it, and a host
  can override it like the other getters.

## Open Points

- A killed process cannot clean up, and neither can the processes it
  started. `beforeKill` only picks the moment of the kill.
- A process run with `ggRunProcess` is never interrupted. A cancelled job
  waits until such a command is through.
- A scope only sees the processes started through `ggStartProcess` or
  `GgProcessWrapper`. A plain `Process.start` is not tracked.
