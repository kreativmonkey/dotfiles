# Central Agent Configuration

Shared configuration root for multiple local AI agent clients (Claude Code,
OpenCode, Gemini CLI, Codex CLI, Cursor, Pi Agent). One directory, one source
of truth — linked or generated into client-specific locations.

## Core Idea

```
~/.agents/           ← canonical source
├── AGENTS.md        ← global instructions (loaded by every client)
├── skills/          ← reusable workflows (one dir per skill)
├── agents/          ← subagent specs (canonical format)
├── sync-agents.py   ← generates client-specific subagent files
├── setup.sh         ← interactive or per-client setup (symlinks, skills)
├── verify.sh        ← checks all symlinks and reports issues
├── memory/          ← shared global file-based memory
└── link-project-memory.sh  ← wires project memories into the shared system
```

Clients read from this directory via symlinks or imports. No manual editing
of client-specific files — everything flows from the canonical sources.

## Features

- **Single source of truth** — one `AGENTS.md`, one `skills/` directory, one `agents/` directory shared across all clients
- **Multi-client support** — works with Claude Code, OpenCode, Gemini CLI, Codex CLI, Cursor, and Pi Agent
- **Centralized skills** — reusable workflows defined once, loaded everywhere
- **Subagent code generation** — canonical agent specs are converted to client-specific formats automatically
- **Shared memory** — file-based memory layer shared across all agents, global and per-project
- **Worktree-aware** — project memory can be shared between main checkout and worktrees
- **No secrets in the repo** — credentials stay in host-specific config or environment variables
- **Client-native integration** — each client uses its own wiring mechanism (symlinks, imports) without modification

## Requirements

- **Operating system:** Linux or macOS (shell scripts use `bash`, `realpath`, `ln`)
- **Python 3** — for `sync-agents.py` (no external dependencies)
- **At least one supported AI agent client** installed:
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
  - [OpenCode](https://opencode.ai)
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli)
  - [Codex CLI](https://github.com/openai/codex)
  - [Cursor](https://cursor.sh)
  - [Pi Agent](https://github.com/earendil-works/pi)
- **Git** (recommended) — for version control of the configuration and for `link-project-memory.sh` to manage `.git/info/exclude`
- **Bash** — setup scripts and skill symlinks assume a POSIX-compatible shell

Optional:
- **Nix** — if using the `nix-dev-env` skill for reproducible dev shells
- **codebase-memory MCP server** — for code graph queries in larger repositories

## Directory Structure

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Global instructions. Clients load this as `AGENTS.md`, `CLAUDE.md`, or via import. Should contain only always-valid rules and load triggers — details belong in skills, docs, or memories. |
| `skills/<name>/SKILL.md` | Global skills. One skill per directory. Reusable workflows triggered by keywords or user intent. |
| `agents/<name>.md` | Canonical subagent specifications. Simple frontmatter format — `sync-agents.py` converts these into client-specific formats. |
| `setup.sh` | Interactive or per-client setup. Links AGENTS.md, skills, and runs sync-agents.py. |
| `verify.sh` | Checks all symlinks, skill counts, and subagent files. Reports OK/WARN/FAIL per client. |
| `sync-agents.py` | Generates subagent files for Claude Code, OpenCode, Gemini CLI, and Cursor from the canonical specs. |
| `memory/` | Shared global file-based memory. Declarative facts that persist across sessions. Read `memory/README.md` for write rules. |
| `link-project-memory.sh` | Wires project memories under `<project>/.agents/memory/` and creates Claude project symlinks. Also handles worktree memory sharing. |
| `plugins/` | Local plugin and marketplace metadata. |

## Client Wiring

Each client needs three things: global instructions, skills, and subagents.
The wiring differs per client because each has its own configuration format.

| Client | Instructions | Skills | Subagents |
| --- | --- | --- | --- |
| Claude Code | symlink `AGENTS.md` → `CLAUDE.md` | directory symlink | generated via `sync-agents.py` |
| OpenCode | symlink `AGENTS.md` | reads `~/.agents/skills` natively | generated via `sync-agents.py` |
| Gemini CLI | import directive in `GEMINI.md` | directory symlink | generated via `sync-agents.py` |
| Codex CLI | symlink `AGENTS.md` | individual skill symlinks (must not overwrite `.system/`) | no custom subagents |
| Cursor | symlink `AGENTS.md` | individual skill symlinks | generated via `sync-agents.py` |
| Pi Agent | symlink `AGENTS.md` | individual skill symlinks | no custom subagents |

## Setup

### 1. Clone or place this directory

```bash
git clone <repo> ~/.agents
# or copy/symlink to ~/.agents
```

### 2. Run setup.sh

Interactive (menu):

```bash
~/.agents/setup.sh
```

Per-client:

```bash
~/.agents/setup.sh claude     # nur Claude Code
~/.agents/setup.sh opencode   # nur OpenCode
~/.agents/setup.sh gemini     # nur Gemini CLI
~/.agents/setup.sh codex      # nur Codex CLI
~/.agents/setup.sh pi         # nur Pi Agent
~/.agents/setup.sh all        # alle Clients
```

The script links `AGENTS.md`, skills, and runs `sync-agents.py` for the
selected client. Re-run after adding new global skills.

### 3. Verify setup

```bash
~/.agents/verify.sh           # alle installierten Clients prüfen
~/.agents/verify.sh claude    # nur Claude Code prüfen
```

### 4. Wire project memory

For each project that should share memory across agents:

```bash
~/.agents/link-project-memory.sh /path/to/project
```

For worktrees sharing the main checkout's memory:

```bash
~/.agents/link-project-memory.sh /path/to/worktree /path/to/main-checkout
```

The script:
- Creates `<project>/.agents/memory/` and symlinks it into Claude's project memory
- Merges existing Claude memory files into the shared location
- Adds `.agents/` to `.git/info/exclude` (local, not committed)

## Subagent Format

Canonical specs live in `agents/<name>.md` with this format:

```markdown
---
name: my-agent
description: one line — used by the main agent to decide when to call this subagent
tools: bash, read, grep, glob, edit, write, webfetch, task
model: medium            # small | medium | large | inherit — kleinste Stufe,
                         # die die Aufgabe sicher löst (siehe AGENTS.md,
                         # Abschnitt Delegation / Modell-Routing)
temperature: 0.1
---

<markdown body = system prompt>
```

### Modell-Stufen über Tools hinweg

`model:` nennt eine **logische Stufe**, kein Vendor-Modell — dieselbe Spec-Datei
soll in jedem Tool richtig routen. Die Zuordnung Stufe → Modell-ID pro Tool
steht in `models.json`:

| Stufe | Claude Code | OpenCode | Gemini CLI |
| --- | --- | --- | --- |
| `small` | `haiku` | `ollama/gemma4:latest` | `gemini-3-flash-preview` |
| `medium` | `sonnet` | `ollama/qwen3-coder:30b` | `gemini-3-flash-preview` |
| `large` | `opus` | *(unbelegt → erbt)* | `gemini-3-preview` |

- Fehlt eine Stufe für ein Tool, lässt `sync-agents.py` das `model`-Feld weg —
  das Tool erbt sein Session-Modell. Kein stiller Fallback auf ein falsches
  Modell.
- Alte Specs mit `haiku`/`sonnet`/`opus` gelten als Synonyme für
  `small`/`medium`/`large`. Ein unbekannter Wert bricht den Sync ab, bevor
  irgendeine Datei geschrieben wird.
- `sync-agents.py` protokolliert pro Agent, in welchen Tools die Stufe wirklich
  gepinnt wurde.
- **Codex CLI** kennt keine eigenen Subagent-Specs (seine Subagents sind
  eingebaut, Feature `multi_agent`). Die Stufe lässt sich dort nur global
  setzen: `default_subagent_model` und `default_subagent_reasoning_effort`
  unter `[agents]` in `~/.codex/config.toml`.
- **Cursor** bleibt unbelegt, solange `cursor-agent` hier nicht installiert ist.

The `sync-agents.py` script reads these and emits client-specific formats.
Claude uses tool names like `Bash`, `Read`; OpenCode uses lowercase booleans;
Gemini and Cursor inherit all tools and rely on the system prompt's guardrails.

## Skills

Skills are reusable workflows, each in `skills/<name>/SKILL.md`. They contain
instructions, triggers, and references. Clients that support skills load them
via symlinks.

Key workflow skills:

| Skill | Purpose |
| --- | --- |
| `worktree-task` | One task = one branch = one worktree. Isolates features, bugfixes, and experiments. |
| `nix-dev-env` | Add a declarative Nix dev shell and `justfile` to a project. |
| `project-onboard` | Bring a new project onto the standard workflow in one pass. |
| `graphify` | Create and query codebase/document knowledge graphs. |
| `diagnosing-bugs` | Structured debugging loop for hard bugs and regressions. |
| `test-before-handoff` | Actually run or test changed code before handoff. |
| `memory-gc` | Audit memory directories for stale or duplicate entries. |
| `incident-postmortem` | Capture complex incident learnings as memory or ADR. |
| `ponytail*` | Minimalism and over-engineering checks. |
| `caveman*` | Compressed communication, review, and commit formats. |

List all installed skills:

```bash
find ~/.agents/skills -maxdepth 2 -name SKILL.md -printf '%h\n' | sed 's#.*/##' | sort
```

## Subagents

| Agent | Purpose |
| --- | --- |
| `ci-debugger` | Diagnose CI failures in GitLab, Forgejo, and GitHub Actions. |
| `flux-debugger` | Debug Flux and GitOps reconciliation. |
| `k8s-debugger` | Analyze Kubernetes runtime issues (read-only). |
| `planner` | Structure implementation plans before coding. |
| `security` | Defensive security reviews. |
| `testing` | Write, run, and diagnose tests. |

Add new agents by creating `agents/<name>.md` and running `sync-agents.py`.

## Memory System

File-based, shared across all agents. Two layers:

- **Global** `~/.agents/memory/` — project-independent facts (preferences,
  infrastructure, conventions)
- **Project** `<project>/.agents/memory/` — project-specific, git-excluded,
  wired via `link-project-memory.sh`

Write rules live in `memory/README.md`. Core principle: store declarative facts
that save future re-work, not session logs or task progress.

## Codebase Memory (Code Graph)

For larger repositories, use the graph before grep. The shared MCP server
`codebase-memory-mcp` provides symbol-level queries. Index each repo once
from the main checkout; worktrees reuse that index.

## Secrets And Host-Specific Data

Do not commit or share:

- Tokens, passwords, API keys, or OAuth files
- Local auth files (`~/.codex/auth.json`, `~/.claude/.credentials.json`, etc.)
- Host-specific IPs, private URLs, or local project paths
- Backup directories (`.backup-*`)

Document MCP servers as templates. Set credentials per user through
environment variables, secret stores, or local unshared config files.

## Maintenance

- Keep `AGENTS.md` short — always-valid rules and load triggers only
- Put detailed workflows in skills, docs, or memories
- Edit subagents only in `agents/<name>.md`, then re-run `sync-agents.py`
- Do not manually edit generated files in client directories
- Read `memory/README.md` before writing memories
- After adding new global skills: `./setup.sh all` to re-link for all clients
