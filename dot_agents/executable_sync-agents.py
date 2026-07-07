#!/usr/bin/env python3
"""Generate tool-specific subagent files from canonical specs in ~/.agents/agents/.

Canonical format (one file per agent), simple line-based frontmatter:

    ---
    name: my-agent
    description: one line, used by the main agent to decide when to call this subagent
    tools: bash, read, grep, glob, edit, write, webfetch, task
    model: sonnet            # sonnet | opus | inherit
    temperature: 0.1
    ---
    <markdown body = system prompt>

Outputs:
    ~/.claude/agents/<name>.md            (Claude Code)
    ~/.config/opencode/agent/<name>.md    (OpenCode)
    ~/.gemini/agents/<name>.md            (Gemini CLI)
"""
import os
import sys

HOME = os.path.expanduser("~")
SRC = os.path.join(HOME, ".agents", "agents")

OUT = {
    "claude": os.path.join(HOME, ".claude", "agents"),
    "opencode": os.path.join(HOME, ".config", "opencode", "agent"),
    "gemini": os.path.join(HOME, ".gemini", "agents"),
}

# logical tool name -> Claude Code tool name
CLAUDE_TOOLS = {
    "bash": "Bash", "read": "Read", "grep": "Grep", "glob": "Glob",
    "edit": "Edit", "write": "Write", "webfetch": "WebFetch", "task": "Task",
}
# OpenCode tool keys we explicitly set (true if granted, false otherwise)
OPENCODE_KEYS = ["read", "grep", "glob", "bash", "edit", "write", "webfetch", "task"]

# logical model -> Claude alias
CLAUDE_MODEL = {"sonnet": "sonnet", "opus": "opus", "inherit": None}

BANNER = "<!-- GENERATED from ~/.agents/agents/{name}.md by sync-agents.py — do not edit here -->"


def parse(path):
    text = open(path, encoding="utf-8").read()
    if not text.startswith("---"):
        raise ValueError(f"{path}: missing frontmatter")
    _, fm, body = text.split("---", 2)
    meta = {}
    for line in fm.strip().splitlines():
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        meta[k.strip()] = v.strip()
    tools = [t.strip() for t in meta.get("tools", "").split(",") if t.strip()]
    return meta, tools, body.lstrip("\n")


def y(s):
    """Quote a scalar for YAML if needed."""
    if any(c in s for c in ":#") or s.strip() != s:
        return '"' + s.replace('"', '\\"') + '"'
    return s


def emit_claude(name, meta, tools, body):
    fm = [f"name: {name}", f"description: {y(meta['description'])}"]
    mapped = [CLAUDE_TOOLS[t] for t in tools if t in CLAUDE_TOOLS]
    if mapped:
        fm.append("tools: " + ", ".join(mapped))
    m = CLAUDE_MODEL.get(meta.get("model", "inherit"))
    if m:
        fm.append(f"model: {m}")
    return frontmatter(fm, name, body)


def emit_opencode(name, meta, tools, body):
    fm = [f"description: {y(meta['description'])}", "mode: subagent"]
    if meta.get("temperature"):
        fm.append(f"temperature: {meta['temperature']}")
    fm.append("tools:")
    for k in OPENCODE_KEYS:
        fm.append(f"  {k}: {'true' if k in tools else 'false'}")
    # model intentionally omitted -> OpenCode inherits the configured default,
    # avoiding a hardcoded provider/model id that may not match the user's config.
    return frontmatter(fm, name, body)


def emit_gemini(name, meta, tools, body):
    fm = [f"name: {name}", f"description: {y(meta['description'])}"]
    # Gemini tool identifiers differ across versions; inherit all tools and rely on
    # the system prompt's guardrails. Gemini has no sonnet/opus aliases, so always
    # inherit the session model.
    fm.append("model: inherit")
    if meta.get("temperature"):
        fm.append(f"temperature: {meta['temperature']}")
    return frontmatter(fm, name, body)


def frontmatter(fm_lines, name, body):
    return "---\n" + "\n".join(fm_lines) + "\n---\n" + BANNER.format(name=name) + "\n\n" + body


EMITTERS = {"claude": emit_claude, "opencode": emit_opencode, "gemini": emit_gemini}


def main():
    if not os.path.isdir(SRC):
        sys.exit(f"no canonical agents dir: {SRC}")
    for d in OUT.values():
        os.makedirs(d, exist_ok=True)
    specs = sorted(f for f in os.listdir(SRC) if f.endswith(".md"))
    if not specs:
        sys.exit(f"no .md specs in {SRC}")
    for f in specs:
        name = f[:-3]
        meta, tools, body = parse(os.path.join(SRC, f))
        meta.setdefault("name", name)
        for tool, emit in EMITTERS.items():
            out = os.path.join(OUT[tool], f"{name}.md")
            open(out, "w", encoding="utf-8").write(emit(name, meta, tools, body))
        print(f"  {name}: claude, opencode, gemini")
    print(f"Synced {len(specs)} agent(s) to 3 tools.")


if __name__ == "__main__":
    main()
