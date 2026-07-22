---
name: worktree-task
description: Startet eine neue Aufgabe (Feature, Bugfix, Experiment) in einem eigenen Git-Worktree und räumt ihn nach dem Merge ab. Verwenden BEVOR im Repo an einer neuen Aufgabe gearbeitet wird — auch bei "worktree", "neuer Branch", "Feature anfangen", "Bugfix starten".
---

# Worktree-Workflow

Kernregel (globale AGENTS.md): **Ein Task = ein Branch = ein Worktree.**
Haupt-Checkout bleibt auf dem Default-Branch (nur Review, Pulls, Merges).
Nie zwei Agents im selben Worktree.

## Anlegen

**Zuerst den Default-Branch aktualisieren** — solange keine andere Anweisung
vorliegt, den neuen Branch immer auf einem frischen `main` aufsetzen, damit
der spätere PR nicht auf veraltetem Stand fußt:

```bash
git -C <haupt-checkout> switch main && git -C <haupt-checkout> pull --ff-only
git worktree add ../<repo>-worktrees/<slug> -b <typ>/<slug> main
```

- Branch-Typen: `feat/`, `fix/`, …; Verzeichnisname = Branch-Slug.
- Ablageort: Schwesterverzeichnis neben dem Repo. Projekt-AGENTS.md kann einen
  anderen Ort vorgeben (z. B. Homelab: `homelab-worktrees/`).
- Tool-native Worktree-Features (etwa Claude Codes `--worktree` /
  Subagent-Isolation) sind erlaubt, dieselben Regeln gelten. Legt das Tool
  Worktrees im Repo ab (Claude: `.claude/worktrees/`), den Pfad in
  `.git/info/exclude` aufnehmen (lokal, nicht committen — analog `.agents/`).

## Setup im Worktree

- Gitignorierte Dateien (`.env` etc.) kommen nicht mit — bei Bedarf aus dem
  Haupt-Checkout kopieren. Danach wie üblich `nix develop`.
- Memory teilen (bei längerlebigen Worktrees):
  `~/.agents/link-project-memory.sh <worktree-pfad> <haupt-checkout>` —
  sonst legt die Session ein eigenes, fragmentiertes Projekt-Memory an.

## Aufräumen

- Nach dem Merge: `git worktree remove <pfad>` und den Branch löschen.
- `git worktree list` zeigt Verwaistes. Nicht auf fremden/alten Worktrees
  aufsetzen.
