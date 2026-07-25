# Central Agent Configuration

This directory is the shared configuration root for local AI agent clients. It
keeps global instructions, skills, memories, and canonical subagent definitions
in one place, then links or generates client-specific files as needed.

The local source of truth is:

```text
~/.agents/
```

## Contents

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Global instructions loaded by clients as `AGENTS.md`, `CLAUDE.md`, or an import. |
| `skills/<name>/SKILL.md` | Global skills. One skill per directory. |
| `agents/<name>.md` | Canonical subagent specifications. Clients do not all read this format directly. |
| `sync-agents.py` | Generates client-specific subagent files. |
| `memory/` | Shared global file-based memory. |
| `link-project-memory.sh` | Wires project memories under `<project>/.agents/memory/` and Claude project symlinks. |
| `plugins/` | Local plugin and marketplace metadata. |

Project memories do not belong in this directory. They live in each project at
`<project>/.agents/memory/` and should be excluded from Git locally.

## Connected Agent Clients

| Client | Global instructions | Skills | Subagents | Client configuration |
| --- | --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md -> ~/.agents/AGENTS.md` | `~/.claude/skills -> ~/.agents/skills` | generated to `~/.claude/agents/` | `~/.claude/settings.json`, `~/.claude/settings.local.json` |
| OpenCode | `~/.config/opencode/AGENTS.md -> ~/.agents/AGENTS.md` | reads `~/.agents/skills` natively | generated to `~/.config/opencode/agent/` | `~/.config/opencode/opencode.json` |
| Gemini CLI | `~/.gemini/GEMINI.md` imports `~/.agents/AGENTS.md` | `~/.gemini/skills -> ~/.agents/skills` | generated to `~/.gemini/agents/` | `~/.gemini/settings.json`, `~/.gemini/GEMINI.md` |
| Codex CLI | `~/.codex/AGENTS.md -> ~/.agents/AGENTS.md` | individual symlinks in `~/.codex/skills/`; no directory symlink because `.system/` must remain in place | no generated custom subagents | `~/.codex/config.toml`, `~/.codex/hooks.json`, `~/.codex/rules/` |
| Cursor | intended: `~/.cursor/AGENTS.md`, `~/.cursor/skills/`, `~/.cursor/agents/` | individual symlinks, same pattern as Codex | generator supports `~/.cursor/agents/` | `~/.cursor/`, optionally `~/.cursor/mcp.json` |
| Pi Agent | no global instruction file wired at the moment | individual symlinks in `~/.pi/agent/skills/` | no generated subagents | `~/.pi/agent/settings.json`, `~/.pi/agent/extensions/` |

Current local state notes:

- Cursor support is present in the generator, but the local `~/.cursor/`
  directory currently only contains hooks. Create `AGENTS.md`, `skills/`,
  `agents/`, and `mcp.json` there before using Cursor with this setup.
- Pi Agent is installed under `~/.pi/agent/`. Currently only the
  `orchestration` skill is linked back to `~/.agents/skills`; global
  `AGENTS.md` instructions and subagent sync are not visibly wired for Pi.

## How To Use

1. Place this directory at `~/.agents`.
2. Do not copy secrets, tokens, or host-specific paths from another machine.
   MCP configuration should be recreated per user and per host.
3. Link global instructions into the clients:

```bash
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md
mkdir -p ~/.config/opencode
ln -sfn ~/.agents/AGENTS.md ~/.config/opencode/AGENTS.md
mkdir -p ~/.codex
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

4. Gemini uses an import file instead of only a symlink. Put this at the top of
   `~/.gemini/GEMINI.md`:

```text
@/home/<user>/.agents/AGENTS.md
```

5. Link skills:

```bash
ln -sfn ~/.agents/skills ~/.claude/skills
ln -sfn ~/.agents/skills ~/.gemini/skills
mkdir -p ~/.codex/skills
for d in ~/.agents/skills/*/; do ln -sfn "$(realpath "$d")" ~/.codex/skills/"$(basename "$d")"; done
mkdir -p ~/.pi/agent/skills
ln -sfn ~/.agents/skills/orchestration ~/.pi/agent/skills/orchestration
```

Codex uses individual skill symlinks because `~/.codex/skills/.system/`
contains Codex-managed built-in skills and must remain intact.

Pi is currently wired only for the `orchestration` skill. Before linking all
global skills into Pi, verify that Pi supports the same skill structure and
trigger semantics reliably.

6. Generate subagents:

```bash
python3 ~/.agents/sync-agents.py
```

Generated files are written to:

```text
~/.claude/agents/
~/.config/opencode/agent/
~/.gemini/agents/
~/.cursor/agents/
```

7. Wire project memory for a project:

```bash
~/.agents/link-project-memory.sh /path/to/project
```

For worktrees that should share the main checkout memory:

```bash
~/.agents/link-project-memory.sh /path/to/worktree /path/to/main-checkout
```

## Maintenance Rules

- Keep `AGENTS.md` short. It should contain only always-valid rules and load
  triggers.
- Put detailed workflows in skills, docs, or memories.
- Add new global skills under `skills/<name>/SKILL.md`.
- Re-run the Codex skill symlink loop after adding a new global skill.
- Edit subagents only under `agents/<name>.md`, then run `sync-agents.py`.
- Do not manually edit generated files in client-specific directories.
- Read `memory/README.md` before writing memories.

## Global Skills

Skills live under `skills/`. Important workflow examples:

| Skill | Purpose |
| --- | --- |
| `worktree-task` | One task = one branch = one worktree. |
| `nix-dev-env` | Add a declarative Nix dev shell and `justfile` to a project. |
| `project-onboard` | Bring a new project onto the standard workflow. |
| `graphify` | Create and query codebase/document knowledge graphs. |
| `diagnosing-bugs` | Structured debugging loop. |
| `test-before-handoff` | Actually run or test changed code before handoff. |
| `memory-gc` | Audit memory directories for stale or duplicate entries. |
| `incident-postmortem` | Capture complex incident learnings as memory or ADR. |
| `ponytail*` | Minimalism and over-engineering checks. |
| `caveman*` | Compressed communication, review, and commit formats. |

List all installed global skills:

```bash
find ~/.agents/skills -maxdepth 2 -name SKILL.md -printf '%h\n' | sed 's#.*/##' | sort
```

## Subagents

Canonical subagents live under `agents/`:

| Agent | Purpose |
| --- | --- |
| `ci-debugger` | Diagnose CI failures in GitLab, Forgejo, and GitHub Actions. |
| `flux-debugger` | Debug Flux and GitOps reconciliation. |
| `k8s-debugger` | Analyze Kubernetes runtime issues read-only. |
| `planner` | Structure implementation plans. |
| `security` | Defensive security reviews. |
| `testing` | Write, run, and diagnose tests. |

Subagents are generated rather than symlinked because each client uses a
different file format.

## MCPs

MCPs are configured per client. This README documents names, transports, and
configuration locations only. Secrets belong in local client configuration,
environment variables, or separate tool configuration files.

### Codex CLI

Configuration: `~/.codex/config.toml`

| MCP | Transport | Purpose / note |
| --- | --- | --- |
| `codebase-memory` | stdio: `~/.local/bin/codebase-memory-mcp` | Code graph for repositories; `search_graph` and `search_code` require approval. |
| `forgejo` | stdio: `npx -y @ric_/forgejo-mcp` | Forgejo/Gitea API. Token and URL are configured in `env`. |
| `ha-mcp` | HTTP URL | Home Assistant MCP over LAN. |
| `netbird` | stdio: `~/go/bin/mcp-netbird` | NetBird API. Token and host are configured in `env`. |
| `akuvox` | stdio: `uv run --project ... akuvox-mcp` | Akuvox device fleet. |
| `proxmox-mcp-plus` | stdio: `uvx proxmox-mcp-plus` | Proxmox; uses `PROXMOX_MCP_CONFIG=~/.config/proxmox-mcp/config.json`. |
| `all-inkl` | stdio: `npx -y mcp-all-inkl` | ALL-INKL/KAS API. Credentials are configured in `env`. |
| `n8n-mcp` | HTTP URL | n8n MCP server. Auth is passed via HTTP header. |

### OpenCode

Configuration: `~/.config/opencode/opencode.json`

| MCP | Transport | Purpose / note |
| --- | --- | --- |
| `headroom` | local command: `~/.local/bin/headroom mcp serve` | Context compression via Headroom. |
| `filesystem` | local command: `npx -y @modelcontextprotocol/server-filesystem ~/` | Filesystem access. |
| `git` | local command: `uvx mcp-server-git --repository .` | Git operations for the current repository. |
| `kubernetes` | local command: `npx -y kubernetes-mcp-server@latest` | Kubernetes read/debug tooling. |
| `memory` | local command: `npx -y @modelcontextprotocol/server-memory` | MCP memory server. |
| `ripgrep` | local command: `npx -y mcp-ripgrep` | Fast search via ripgrep. |

### Gemini CLI

Configuration: `~/.gemini/settings.json`

| MCP | Transport | Purpose / note |
| --- | --- | --- |
| `codebase-memory` | stdio: `~/.local/bin/codebase-memory-mcp` | Code graph for repositories. |

### Claude Code

Client configuration: `~/.claude/settings.json`

No `mcpServers` block is currently visible in `settings.json`. The central
memory records `codebase-memory` as a user-scope MCP for Claude Code. On a new
machine, register Claude MCPs with the client command and verify them there
instead of copying another host's local configuration.

### Cursor

Expected MCP configuration: `~/.cursor/mcp.json`

This file does not currently exist locally. The central memory describes
`codebase-memory` as the intended Cursor MCP binding. Create `~/.cursor/mcp.json`
and approve the server in Cursor Agent before relying on it.

### Pi Agent

Client configuration: `~/.pi/agent/settings.json`

No MCP configuration block is currently visible. `~/.pi/agent/` contains
settings, auth, sessions, extensions, and `skills/`. Document Pi MCPs once the
expected Pi MCP configuration format is clear.

## Codebase-Memory Standard

For larger repositories, use the graph before grep. The shared MCP server is:

```text
~/.local/bin/codebase-memory-mcp
```

Index each repository once, using the main checkout:

```bash
codebase-memory-mcp cli index_repository '{"repo_path":"/abs/path"}'
```

Worktrees should use the main checkout index instead of indexing parent
directories or each worktree separately.

## Secrets And Host-Specific Data

Do not share:

- Tokens, passwords, API keys, or OAuth files.
- Local auth files such as `~/.codex/auth.json`,
  `~/.claude/.credentials.json`, `~/.gemini/oauth_creds.json`, or
  `~/.pi/agent/auth.json`.
- Host-specific IPs, private URLs, and local project paths unless they are
  intentionally part of the target environment.
- Backups under `.backup-*`, because they may contain old secrets.

For reusable distributions, document MCP servers as templates. Set credentials
per user through environment variables, secret stores, or local unshared config
files.
