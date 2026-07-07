# Memory-Format

Schreibregeln für Memories — gelten global (`~/.agents/memory/`) und pro
Projekt (`<projekt>/.agents/memory/`). Vor dem Anlegen oder Ändern eines
Memorys lesen.

## Regeln

- **Speichern, was künftiges Nachsteuern erspart.** Das wertvollste Memory
  ist das, das dem User eine Wiederholung oder Korrektur erspart. KEIN
  Task-Fortschritt, keine Session-Ergebnisse, kein Erledigt-Protokoll.
- **Deklarative Fakten, keine Selbst-Anweisungen.** „User bevorzugt knappe
  Antworten" ✓ — „Antworte immer knapp" ✗. Imperative Memories werden in
  späteren Sessions als Direktive re-gelesen und können den aktuellen
  Auftrag überschreiben.
- **Eine Datei = ein Fakt.** Dateiname = kebab-case-Slug (`<name>.md`).
- Vor dem Anlegen prüfen, ob eine bestehende Datei das Thema abdeckt —
  aktualisieren statt duplizieren; falsch Gewordenes löschen.
- Projektbezogene Fakten ins Projekt-Memory, projektübergreifende ins globale.
- Relative Daten („gestern", „letzte Woche") in absolute umwandeln.
- Nichts speichern, was aus Code, Repo oder Git-History ableitbar ist.
- Nach dem Schreiben eine Zeile im Index `MEMORY.md` ergänzen:
  `- [Titel](datei.md) — Kurzbeschreibung`. Der Index enthält nur Zeiger,
  nie Inhalt.

## Datei-Template

```markdown
---
name: <kebab-case-slug>
description: <Einzeiler — wird zur Relevanzprüfung beim Recall genutzt>
metadata:
  type: user | feedback | project | reference
---

<Der Fakt. Bei type feedback/project zusätzlich:>
**Why:** <warum das gilt / wie es dazu kam>
**How to apply:** <wie es anzuwenden ist>
```

- `type`: `user` = wer der User ist (Rolle, Präferenzen) · `feedback` =
  Arbeitsanweisungen/Korrekturen des Users · `project` = laufende Arbeit,
  Ziele, Constraints · `reference` = Zeiger auf Externes (URLs, Tickets).
- Verweise auf andere Memories per `[[name]]` (Slug der Zieldatei); auch auf
  noch nicht existierende erlaubt — markiert Schreibenswertes.
