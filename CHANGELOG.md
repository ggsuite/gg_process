# Changelog

## Unreleased

### Changed

- Use ggwsm in pipelines

## 1.2.0 - 2026-08-13

### Changed

- Rework copyright headers

### Fixed

- Cleanup copy right headers. Update to dart 3.13. Auto fixes.
- Cleanup copy right headers. Update to dart 3.13. Auto fixes. Setup quick-check pipeline.

## 1.1.7 - 2026-08-11

### Added

- `GgProcessDelegate.current` performs every process the gg suite starts,
and can be replaced. `GgProcessWrapper` routes through it, as do the new
`ggRunProcess` / `ggStartProcess` drop-in replacements for `Process.run`
and `Process.start`.
- `GgPlatformDelegate.current` answers the `Platform` questions and holds
the exit code (`ggExitCode`), so a build without a working `dart:io` can
answer them itself.
- Add .gitattributes file

### Changed

- Provide gg via npm
- Fix shell changes

## 1.1.6 - 2024-04-13

### Removed

- dependency pana

## 1.1.5 - 2024-04-12

### Removed

- dependency to gg_install_gg, remove ./check script

## 1.1.4 - 2024-04-09

### Removed

- 'Pipline: Disable cache'

## 1.1.3 - 2024-04-09

### Changed

- Rework changelog
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

## 1.1.2 - 2024-01-01

- `GgFakeProcess.stdin` returns a mock now

## 1.1.1 - 2024-01-01

- Add latest dependencies

## 1.1.0 - 2024-01-01

- Add `GgFakeProcess:exitWithException`

## 1.0.7 - 2024-01-01

- Initial version.
