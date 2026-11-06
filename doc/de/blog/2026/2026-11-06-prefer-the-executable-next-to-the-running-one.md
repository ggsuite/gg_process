<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Programme neben dem laufenden Programm bevorzugen

## Motivation

- Seit 1.4.0 startet `GgProcessDelegate` unter Windows Batch-Dateien wie
  `flutter` über ihren vollen Pfad, damit sie ohne Shell laufen.
- Die Suche schaute nur in `PATH`. Windows selbst sucht zuerst im Ordner
  des laufenden Programms und findet dort `dart.exe`, wenn ein
  Dart-Programm `dart` startet.
- Flutter legt einen `dart.bat`-Wrapper in den `PATH`. Die Suche nahm
  diesen Wrapper statt des `dart.exe`, das Windows gestartet hätte.
- Der Wrapper startet deutlich langsamer. Werkzeuge mit verschachtelten
  `dart test`-Läufen liefen in ihre Timeouts.

## Strategie

- Jeden Namen, den Windows ohne Hilfe startet, unverändert lassen.
- Vor `PATH` den Ordner des laufenden Programms prüfen, wie es
  `CreateProcess` tut.
- Diesen Ordner über `GgPlatformDelegate` lesen, damit Tests ihn
  vortäuschen können.

## Ordner des laufenden Programms

- `GgWindowsExecutable.resolve` lässt einen nackten Namen stehen, wenn der
  Ordner von `Platform.resolvedExecutable` ihn als `.exe` oder `.com`
  enthält.
- Nur sonst sucht es eine `.bat`- oder `.cmd`-Datei in `PATH`.
- `flutter`, `npm` und `pnpm` lösen weiter zu ihren Batch-Dateien auf:
  neben `dart.exe` liegt kein `.exe` von ihnen.

## GgPlatformDelegate.resolvedExecutable

- Neuer Getter, der `Platform.resolvedExecutable` liefert.
- Hosts ohne `dart:io` überschreiben ihn wie die anderen Getter.

## Ergebnis

- `dart` aus einem Dart-Programm ist wieder dasselbe `dart.exe` wie vor
  1.4.0.
- Verschachtelte `dart test`-Läufe sind so schnell wie vorher.

## Offene Punkte

- Windows sucht vor `PATH` auch im aktuellen Ordner und in den
  Systemordnern. Die Suche tut das nicht: `PATH` enthält die Systemordner
  meist, und eine Batch-Datei dort wird so oder so gefunden.
