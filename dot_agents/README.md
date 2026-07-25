# Central Agent Configuration

Shared configuration root for multiple local AI agent clients (Claude Code,
OpenCode, Gemini CLI, Codex CLI, Cursor). One directory, one source of truth —
linked or generated into client-specific locations.

## Core Idea

```
~/.agents/           ← canonical source
├── AGENTS.md        ← global instructions (loaded by every client)
├── skills/          ← reusable workflows (one dir per skill)
├── agents/          ← subagent specs (canonical format)
├── sync-agents.py   ← generates client-specific subagent files
├── memory/          ← shared global file-based memory
└── link-project-memory.sh  ← wires project memories into the shared system
```

Clients read from this directory via symlinks or imports. No manual editing
of client-specific files — everything flows from the canonical sources.

## Directory Structure

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Global instructions. Clients load this as `AGENTS.md`, `CLAUDE.md`, or via import. Should contain only always-valid rules and load triggers — details belong in skills, docs, or memories. |
| `skills/<name>/SKILL.md` | Global skills. One skill per directory. Reusable workflows triggered by keywords or user intent. |
| `agents/<name>.md` | Canonical subagent specifications. Simple frontmatter format — `sync-agents.py` converts these into client-specific formats. |
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

## Setup

### 1. Clone or place this directory

```bash
git clone <repo> ~/.agents
# or copy/symlink to ~/.agents
```

### 2. Link global instructions

```bash
# Claude Code
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md

# OpenCode
mkdir -p ~/.config/opencode
ln -sfn ~/.agents/AGENTS.md ~/.config/opencode/AGENTS.md

# Codex CLI
mkdir -p ~/.codex
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

**Gemini** uses an import instead of a symlink. Add this line to
`~/.gemini/GEMINI.md`:

```
@/home/<user>/.agents/AGENTS.md
```

### 3. Link skills

```bash
# Claude Code
ln -sfn ~/.agents/skills ~/.claude/skills

# Gemini CLI
ln -sfn ~/.agents/skills ~/.gemini/skills

# Codex CLI (individual symlinks — .system/ must remain intact)
mkdir -p ~/.codex/skills
for d in ~/.agents/skills/*/; do
  ln -sfn "$(realpath "$d")" ~/.codex/skills/"$(basename "$d")"
done
```

### 4. Generate subagents

```bash
python3 ~/.agents/sync-agents.py
```

Writes to:
- `~/.claude/agents/`
- `~/.config/opencode/agent/`
- `~/.gemini/agents/`
- `~/.cursor/agents/`

Re-run after adding or changing files in `~/.agents/agents/`.

### 5. Wire project memory

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
model: sonnet            # sonnet | opus | inherit
temperature: 0.1
---

<markdown body = system prompt>
```

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
- Re-run Codex skill symlink loop after adding new global skills
