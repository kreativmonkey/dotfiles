# Zentrale Agent-Konfiguration

Dieses Verzeichnis ist die zentrale, tool-uebergreifende Konfiguration fuer
lokale KI-Agent-Clients. Die Idee ist: Regeln, Skills, Memories und Subagenten
werden hier einmal gepflegt und dann in die jeweiligen Client-Konfigurationen
verlinkt oder generiert.

Die lokale Single Source of Truth ist:

```text
~/.agents/
```

## Inhalt

| Pfad | Zweck |
| --- | --- |
| `AGENTS.md` | Globale Instruktionen fuer alle Agenten. Wird von den Clients als `AGENTS.md`, `CLAUDE.md` oder Import geladen. |
| `skills/<name>/SKILL.md` | Globale Skills. Ein Skill pro Unterverzeichnis. |
| `agents/<name>.md` | Kanonische Subagent-Spezifikationen. Nicht direkt von allen Clients lesbar. |
| `sync-agents.py` | Generator fuer client-spezifische Subagent-Dateien. |
| `memory/` | Globales dateibasiertes Memory, geteilt zwischen Tools. |
| `link-project-memory.sh` | Verdrahtet Projekt-Memorys unter `<projekt>/.agents/memory/` und Claude-Projekt-Symlinks. |
| `plugins/` | Lokale Plugin-/Marketplace-Metadaten. |

Projekt-Memorys gehoeren nicht in dieses Verzeichnis. Sie liegen im jeweiligen
Projekt unter `<projekt>/.agents/memory/` und werden lokal git-excluded.

## Angebundene Agent-Clients

| Client | Globale Instruktionen | Skills | Subagenten | Eigentliche Client-Konfiguration |
| --- | --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md -> ~/.agents/AGENTS.md` | `~/.claude/skills -> ~/.agents/skills` | generiert nach `~/.claude/agents/` | `~/.claude/settings.json`, `~/.claude/settings.local.json` |
| OpenCode | `~/.config/opencode/AGENTS.md -> ~/.agents/AGENTS.md` | liest `~/.agents/skills` nativ | generiert nach `~/.config/opencode/agent/` | `~/.config/opencode/opencode.json` |
| Gemini CLI | `~/.gemini/GEMINI.md` importiert `~/.agents/AGENTS.md` | `~/.gemini/skills -> ~/.agents/skills` | generiert nach `~/.gemini/agents/` | `~/.gemini/settings.json`, `~/.gemini/GEMINI.md` |
| Codex CLI | `~/.codex/AGENTS.md -> ~/.agents/AGENTS.md` | einzelne Symlinks in `~/.codex/skills/`; kein Directory-Symlink, weil `.system/` dort bleiben muss | keine generierten Custom-Subagenten | `~/.codex/config.toml`, `~/.codex/hooks.json`, `~/.codex/rules/` |
| Cursor | vorgesehen: `~/.cursor/AGENTS.md`, `~/.cursor/skills/`, `~/.cursor/agents/` | einzelne Symlinks, analog Codex | Generator unterstuetzt `~/.cursor/agents/` | `~/.cursor/`, ggf. `~/.cursor/mcp.json` |

Hinweis zum Ist-Zustand: Cursor ist im Generator vorbereitet, lokal sind unter
`~/.cursor/` aktuell aber nur Hooks vorhanden. Falls Cursor genutzt werden
soll, muessen `AGENTS.md`, `skills/`, `agents/` und `mcp.json` dort angelegt
werden.

## Weitergabe an andere Nutzer

1. Dieses Verzeichnis nach `~/.agents` kopieren oder als Repository klonen.
2. Secrets, Tokens und host-spezifische Pfade nicht aus einer fremden Maschine
   uebernehmen. MCP-Konfigurationen muessen pro Nutzer neu angelegt werden.
3. Globale Instruktionen in die Clients verlinken:

```bash
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md
mkdir -p ~/.config/opencode
ln -sfn ~/.agents/AGENTS.md ~/.config/opencode/AGENTS.md
mkdir -p ~/.codex
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

4. Gemini nutzt eine Import-Datei statt eines reinen Symlinks. Am Anfang von
   `~/.gemini/GEMINI.md` muss stehen:

```text
@/home/<user>/.agents/AGENTS.md
```

5. Skills verlinken:

```bash
ln -sfn ~/.agents/skills ~/.claude/skills
ln -sfn ~/.agents/skills ~/.gemini/skills
mkdir -p ~/.codex/skills
for d in ~/.agents/skills/*/; do ln -sfn "$(realpath "$d")" ~/.codex/skills/"$(basename "$d")"; done
```

Codex bekommt einzelne Skill-Symlinks, weil `~/.codex/skills/.system/`
Codex-eigene Skills enthaelt und erhalten bleiben muss.

6. Subagenten generieren:

```bash
python3 ~/.agents/sync-agents.py
```

Danach liegen die erzeugten Dateien in:

```text
~/.claude/agents/
~/.config/opencode/agent/
~/.gemini/agents/
~/.cursor/agents/
```

7. Projekt-Memory fuer ein Projekt verdrahten:

```bash
~/.agents/link-project-memory.sh /pfad/zum/projekt
```

Fuer Worktrees, die das Memory des Haupt-Checkouts teilen sollen:

```bash
~/.agents/link-project-memory.sh /pfad/zum/worktree /pfad/zum/haupt-checkout
```

## Pflege-Regeln

- `AGENTS.md` bleibt kurz und enthaelt nur immer gueltige Regeln und
  Lade-Trigger.
- Detailwissen kommt in Skills, Docs oder Memories.
- Neue globale Skills werden unter `skills/<name>/SKILL.md` angelegt.
- Nach neuen Skills den Codex-Symlink-Loop erneut ausfuehren.
- Neue oder geaenderte Subagenten werden nur unter `agents/<name>.md`
  bearbeitet; danach `sync-agents.py` ausfuehren.
- Generierte Dateien in Client-Verzeichnissen nicht manuell editieren.
- Memorys erst nach Lesen von `memory/README.md` schreiben.

## Aktuelle globale Skills

Die Skills liegen unter `skills/`. Beispiele fuer die wichtigsten Workflows:

| Skill | Zweck |
| --- | --- |
| `worktree-task` | Ein Task = ein Branch = ein Worktree. |
| `nix-dev-env` | Projekt mit deklarativer Nix-Dev-Shell und `justfile` ausstatten. |
| `project-onboard` | Neues Projekt auf den Standard-Workflow bringen. |
| `graphify` | Codebase-/Dokumenten-Graphen erstellen und abfragen. |
| `diagnosing-bugs` | Strukturierter Debugging-Loop. |
| `test-before-handoff` | Vor Uebergabe geaenderten Code wirklich ausfuehren/testen. |
| `memory-gc` | Memory-Verzeichnis aufraeumen und Dubletten/Staleness finden. |
| `incident-postmortem` | Nach komplexen Incidents Erkenntnisse als Memory/ADR festhalten. |
| `ponytail*` | Minimalismus-/Overengineering-Pruefung. |
| `caveman*` | Stark komprimierte Kommunikation und Review-/Commit-Formate. |

Eine vollstaendige Liste liefert:

```bash
find ~/.agents/skills -maxdepth 2 -name SKILL.md -printf '%h\n' | sed 's#.*/##' | sort
```

## Subagenten

Kanonische Subagenten liegen unter `agents/`:

| Agent | Zweck |
| --- | --- |
| `ci-debugger` | CI-Fehler in GitLab, Forgejo und GitHub Actions diagnostizieren. |
| `flux-debugger` | Flux/GitOps-Reconciliation debuggen. |
| `k8s-debugger` | Kubernetes-Laufzeitprobleme read-only analysieren. |
| `planner` | Plaene strukturieren. |
| `security` | Defensive Security-Reviews. |
| `testing` | Tests schreiben, ausfuehren und diagnostizieren. |

Die Ausgabeformate unterscheiden sich je Client, deshalb werden Subagenten
nicht symlinked, sondern generiert.

## MCPs

MCPs sind client-spezifisch konfiguriert. Diese README dokumentiert nur Namen,
Transport und Speicherort. Secrets stehen in den jeweiligen Client-Konfigs oder
in separaten Tool-Konfigurationen und duerfen nicht in eine geteilte README.

### Codex CLI

Konfiguration: `~/.codex/config.toml`

| MCP | Transport | Zweck / Hinweis |
| --- | --- | --- |
| `codebase-memory` | stdio: `~/.local/bin/codebase-memory-mcp` | Code-Graph fuer Repos; `search_graph` und `search_code` mit Approval. |
| `forgejo` | stdio: `npx -y @ric_/forgejo-mcp` | Forgejo/Gitea API. Token/URL in `env`. |
| `ha-mcp` | HTTP URL | Home Assistant MCP ueber LAN. |
| `netbird` | stdio: `~/go/bin/mcp-netbird` | NetBird API. Token/Host in `env`. |
| `akuvox` | stdio: `uv run --project ... akuvox-mcp` | Akuvox-Geraeteflotte. |
| `proxmox-mcp-plus` | stdio: `uvx proxmox-mcp-plus` | Proxmox; nutzt `PROXMOX_MCP_CONFIG=~/.config/proxmox-mcp/config.json`. |
| `all-inkl` | stdio: `npx -y mcp-all-inkl` | ALL-INKL/KAS API. Zugangsdaten in `env`. |
| `n8n-mcp` | HTTP URL | n8n MCP Server; Auth per HTTP Header. |

### OpenCode

Konfiguration: `~/.config/opencode/opencode.json`

| MCP | Transport | Zweck / Hinweis |
| --- | --- | --- |
| `headroom` | local command: `~/.local/bin/headroom mcp serve` | Kontext-Kompression/Headroom. |
| `filesystem` | local command: `npx -y @modelcontextprotocol/server-filesystem ~/` | Dateisystemzugriff. |
| `git` | local command: `uvx mcp-server-git --repository .` | Git-Operationen auf aktuellem Repo. |
| `kubernetes` | local command: `npx -y kubernetes-mcp-server@latest` | Kubernetes-Read/Debug-Werkzeug. |
| `memory` | local command: `npx -y @modelcontextprotocol/server-memory` | MCP-Memory-Server. |
| `ripgrep` | local command: `npx -y mcp-ripgrep` | Schnelle Suche via ripgrep. |

### Gemini CLI

Konfiguration: `~/.gemini/settings.json`

| MCP | Transport | Zweck / Hinweis |
| --- | --- | --- |
| `codebase-memory` | stdio: `~/.local/bin/codebase-memory-mcp` | Code-Graph fuer Repos. |

### Claude Code

Client-Konfiguration: `~/.claude/settings.json`

In `settings.json` ist aktuell kein `mcpServers`-Block sichtbar. Die zentrale
Memory vermerkt jedoch `codebase-memory` als user-scope MCP fuer Claude Code.
Wenn Claude-MCPs auf einer neuen Maschine eingerichtet werden, sollten sie mit
dem jeweiligen Client-Befehl erneut registriert und anschliessend verifiziert
werden, statt fremde lokale Config-Dateien blind zu kopieren.

### Cursor

Erwartete MCP-Konfiguration: `~/.cursor/mcp.json`

Lokal existiert diese Datei aktuell nicht. Die Memory beschreibt
`codebase-memory` als geplante/urspruengliche Cursor-MCP-Anbindung. Fuer eine
neue Maschine deshalb erst `~/.cursor/mcp.json` anlegen und im Cursor-Agent
freigeben.

## Codebase-Memory Standard

Fuer groessere Repos gilt: Graph vor Grep. Der gemeinsame MCP-Server ist:

```text
~/.local/bin/codebase-memory-mcp
```

Ein Repo wird einmal pro Haupt-Checkout indexiert:

```bash
codebase-memory-mcp cli index_repository '{"repo_path":"/abs/path"}'
```

Worktrees sollen den Index des Haupt-Checkouts verwenden, nicht eigene
Elternverzeichnisse indexieren.

## Secrets und Host-spezifische Daten

Nicht weitergeben:

- Tokens, Passwoerter, API-Keys und OAuth-Dateien.
- Lokale Auth-Dateien wie `~/.codex/auth.json`, `~/.claude/.credentials.json`
  oder `~/.gemini/oauth_creds.json`.
- Host-spezifische IPs, private URLs und lokale Projektpfade, sofern sie nicht
  bewusst Teil der Zielumgebung sind.
- Backups unter `.backup-*`, falls sie alte Secrets enthalten koennten.

Fuer eine wiederverwendbare Distribution sollten MCP-Server als Vorlage
dokumentiert werden, waehrend Credentials pro Nutzer ueber Umgebungsvariablen,
Secret Stores oder lokale, nicht geteilte Config-Dateien gesetzt werden.

