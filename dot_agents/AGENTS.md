# Globale AGENTS.md

Zentrale, tool-übergreifende Instruktionen für alle CLI-Agenten
(Claude Code, OpenCode, Gemini CLI). Single Source of Truth: ~/.agents/AGENTS.md
Hier stehen nur immer gültige Regeln und Lade-Trigger — Details liegen in
Skills, Docs und Memories und werden bei Bedarf geladen.

## Konventionen
- **Best Practice aktiv hinterfragen.** Vorgefundene Setups nicht als korrekt
  übernehmen — vor dem Weiterbauen gegen die offizielle Empfehlung des
  Tools/Operators prüfen; Abweichungen proaktiv benennen: „X läuft auf Y,
  empfohlen wäre Z, weil …". Gilt auch für User-Anweisungen: widerspricht eine
  einer früheren begründeten Entscheidung oder Best Practice, erst kurz die
  Trade-offs benennen, dann umsetzen.
  - Beispiel (nicht wiederholen): CNPG empfiehlt node-lokales Storage, nicht
    geteiltes iSCSI — der Bestand war jahrelang falsch konfiguriert und es
    fiel niemandem auf.

## Testen & Übergabe
**Kein Code gilt als fertig, bevor er in einer Umgebung lief, die seine echten
Abhängigkeiten importiert.** Lesen, `py_compile` und Typ-Raten sind keine
Verifikation — sie übersehen genau die Fehler, die beim User landen (falsche
API-Signaturen, umbenannte kwargs, strikte Decoder, Import-Fehler). Vor jeder
Übergabe: lauffähige Umgebung sicherstellen (Skill **`nix-dev-env`**), den
geänderten Pfad per Test oder echtem Lauf ausführen, Ergebnis nennen. Bugfix =
Test, der den Bug vorher reproduziert. Geht Ausführen nachweislich nicht,
**explizit benennen** was ungetestet bleibt — nie „sollte funktionieren" als
getestet ausgeben. Details & Checkliste: Skill **`test-before-handoff`**.

## Memory
Dateibasiertes Gedächtnis, von allen Tools geteilt: global `~/.agents/memory/`,
pro Projekt `<projekt>/.agents/memory/` (git-excluded, nicht committen).

- **Zu Arbeitsbeginn** den Index `MEMORY.md` im jeweiligen Memory-Verzeichnis
  prüfen und passende Memories lesen (global bei Themen wie Home Assistant,
  Backups, Infrastruktur, Agent-Setup). Memories sind Momentaufnahmen — vor
  Verwendung gegen den Ist-Zustand prüfen.
- **Vor dem Schreiben** eines Memorys die Regeln in
  `~/.agents/memory/README.md` lesen.
- Fehlt in einem Projekt die Verdrahtung (`.agents/memory` bzw. Symlink):
  `~/.agents/link-project-memory.sh [pfad]` ausführen.
- Memory-Inhalte gehören nie hierher — diese Datei lädt in jede Session,
  Memories nur bei Bedarf.

## Codebase-Memory (Code-Graph)
Für Code-Exploration in größeren Repos den MCP-Server `codebase-memory`
nutzen: **Graph vor Grep** — Symbole gezielt abfragen statt Dateien dumpen
(Grep bleibt richtig für exakte Strings, kleine Repos, Nicht-Code). Ein Index
pro Repo, keine Elternverzeichnisse; bei Worktrees den Haupt-Checkout
indexieren und abfragen.

## Git-Worktrees
**Ein Task = ein Branch = ein Worktree.** Features, Bugfixes und Experimente
nie im Haupt-Checkout beginnen — der bleibt auf dem Default-Branch (Review,
Pulls, Merges). Anlegen, Setup, Memory-Verlinkung und Aufräumen: Skill
**`worktree-task`**.

## Selbstoptimierung
Erkenntnisse aus der Arbeit fließen zurück in Skills und Memories — mit
Leitplanken:
- **Skills warten:** Erweist sich ein Skill bei Benutzung als faktisch
  veraltet (Pfad, Kommando, URL), sofort patchen. Verhaltensänderungen
  (Trigger, Vorgehen, neue Regeln) nur vorschlagen.
- **Skills vorschlagen:** Nach einem komplexen Task oder kniffligen Fix
  prüfen, ob ein wiederverwendbarer Workflow entstand — dann als Skill
  vorschlagen (Name, Trigger, Inhalt), erst nach Zustimmung anlegen.
- **Tabu:** Diese AGENTS.md nie eigenständig ändern — Änderungen nur als
  Vorschlag.
- **Transparenz:** Jede Selbständerung (Skill-Patch, Memory-Update) in der
  Antwort benennen.

## Delegation
Vor jeder nicht-trivialen Aufgabe prüfen, ob ein spezialisierter Subagent
passt (z. B. k8s-debugger, testing, security) — dann delegieren statt inline
arbeiten. Den spezifischsten Agent bevorzugen.

## Umgebung
- **Jedes Projekt bekommt eine deklarative Nix-Dev-Shell.** Tooling über
  `nix develop` bereitstellen, nie global installieren (`apt`/`brew`/`pip -g`).
- Fehlt `flake.nix`/`justfile` oder fehlen Tools/Versionen darin: Skill
  **`nix-dev-env`** ausführen statt ad hoc zu beschaffen.
- Wiederkehrende Tasks laufen über `just`; bare `just` zeigt die Übersicht.
