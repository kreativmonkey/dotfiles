#!/usr/bin/env python3
"""Generate tool-specific subagent files from canonical specs in ~/.agents/agents/.

Canonical format (one file per agent), simple line-based frontmatter:

    ---
    name: my-agent
    description: one line, used by the main agent to decide when to call this subagent
    tools: bash, read, grep, glob, edit, write, webfetch, task
    model: medium            # small | medium | large | inherit
    temperature: 0.1
    ---
    <markdown body = system prompt>

`model` names a logical TIER, not a vendor model. The tier -> per-tool model id
mapping lives in ~/.agents/models.json, so one spec routes correctly in every
tool. Legacy Claude aliases (haiku|sonnet|opus) are accepted as tier synonyms.
A tier a tool has no mapping for emits no model field -> that tool inherits its
session model.

Outputs:
    ~/.claude/agents/<name>.md            (Claude Code)
    ~/.config/opencode/agent/<name>.md    (OpenCode)
    ~/.gemini/agents/<name>.md            (Gemini CLI)
    ~/.cursor/agents/<name>.md            (Cursor CLI/IDE)

Codex CLI has no per-agent spec layer (its subagents are built in), so tiers
cannot be expressed per agent there — set `default_subagent_model` /
`default_subagent_reasoning_effort` under `[agents]` in ~/.codex/config.toml.
"""
import json
import os
import sys

HOME = os.path.expanduser("~")
SRC = os.path.join(HOME, ".agents", "agents")

OUT = {
    "claude": os.path.join(HOME, ".claude", "agents"),
    "opencode": os.path.join(HOME, ".config", "opencode", "agent"),
    "gemini": os.path.join(HOME, ".gemini", "agents"),
    "cursor": os.path.join(HOME, ".cursor", "agents"),
}

# logical tool name -> Claude Code tool name
CLAUDE_TOOLS = {
    "bash": "Bash", "read": "Read", "grep": "Grep", "glob": "Glob",
    "edit": "Edit", "write": "Write", "webfetch": "WebFetch", "task": "Task",
}
# OpenCode tool keys we explicitly set (true if granted, false otherwise)
OPENCODE_KEYS = ["read", "grep", "glob", "bash", "edit", "write", "webfetch", "task"]

# tier -> per-tool model id; overridable in ~/.agents/models.json
MODELS_FILE = os.path.join(HOME, ".agents", "models.json")
FALLBACK_MODELS = {"claude": {"small": "haiku", "medium": "sonnet", "large": "opus"}}
MODELS = {}  # populated by load_models() in main()

TIERS = ("small", "medium", "large")
# legacy spec values kept working: Claude aliases named the tier implicitly
TIER_SYNONYMS = {"haiku": "small", "sonnet": "medium", "opus": "large"}


def load_models():
    """Read the tier table, ignoring '//'-prefixed comment keys."""
    try:
        with open(MODELS_FILE, encoding="utf-8") as fh:
            raw = json.load(fh)
    except FileNotFoundError:
        print(f"  note: {MODELS_FILE} missing — using built-in Claude tiers only")
        return FALLBACK_MODELS
    except ValueError as e:
        sys.exit(f"{MODELS_FILE}: invalid JSON — {e}")
    table = {}
    for tool, tiers in raw.items():
        if tool.startswith("//") or not isinstance(tiers, dict):
            continue
        table[tool] = {k: v for k, v in tiers.items() if not k.startswith("//")}
        unknown = set(table[tool]) - set(TIERS)
        if unknown:
            sys.exit(f"{MODELS_FILE}: unknown tier(s) for {tool}: {', '.join(sorted(unknown))}")
    return table


def tier_of(meta, path):
    """Normalize a spec's `model:` value to a tier, or None for inherit."""
    value = meta.get("model", "inherit").strip()
    if value in ("", "inherit"):
        return None
    tier = TIER_SYNONYMS.get(value, value)
    if tier not in TIERS:
        sys.exit(f"{path}: model '{value}' is not a tier "
                 f"({' | '.join(TIERS)} | inherit) or legacy alias "
                 f"({' | '.join(TIER_SYNONYMS)})")
    return tier


def model_for(tool, tier):
    """Model id for this tool+tier, or None -> omit the field (tool inherits)."""
    if tier is None:
        return None
    return MODELS.get(tool, {}).get(tier)

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


def emit_claude(name, meta, tools, body, tier):
    fm = [f"name: {name}", f"description: {y(meta['description'])}"]
    mapped = [CLAUDE_TOOLS[t] for t in tools if t in CLAUDE_TOOLS]
    if mapped:
        fm.append("tools: " + ", ".join(mapped))
    m = model_for("claude", tier)
    if m:
        fm.append(f"model: {m}")
    return frontmatter(fm, name, body)


def emit_opencode(name, meta, tools, body, tier):
    fm = [f"description: {y(meta['description'])}", "mode: subagent"]
    # OpenCode wants a fully qualified "provider/model" id, so it only gets one
    # when models.json maps this tier; otherwise it inherits the session model.
    m = model_for("opencode", tier)
    if m:
        fm.append(f"model: {m}")
    if meta.get("temperature"):
        fm.append(f"temperature: {meta['temperature']}")
    fm.append("tools:")
    for k in OPENCODE_KEYS:
        fm.append(f"  {k}: {'true' if k in tools else 'false'}")
    return frontmatter(fm, name, body)


def emit_gemini(name, meta, tools, body, tier):
    fm = [f"name: {name}", f"description: {y(meta['description'])}"]
    # Gemini tool identifiers differ across versions; inherit all tools and rely on
    # the system prompt's guardrails. Gemini has no tier aliases, so the model id
    # comes from models.json; "inherit" is its documented default.
    fm.append(f"model: {model_for('gemini', tier) or 'inherit'}")
    if meta.get("temperature"):
        fm.append(f"temperature: {meta['temperature']}")
    return frontmatter(fm, name, body)


def emit_cursor(name, meta, tools, body, tier):
    fm = [f"name: {name}", f"description: {y(meta['description'])}"]
    # Cursor's tool identifiers for subagents are not reliably documented
    # (its shell tool is named "Shell", not "Bash"); a wrong name would
    # silently strip the tool. Inherit all tools and rely on the system
    # prompt's guardrails, same approach as Gemini.
    m = model_for("cursor", tier)
    if m:
        fm.append(f"model: {m}")
    return frontmatter(fm, name, body)


def frontmatter(fm_lines, name, body):
    return "---\n" + "\n".join(fm_lines) + "\n---\n" + BANNER.format(name=name) + "\n\n" + body


EMITTERS = {"claude": emit_claude, "opencode": emit_opencode, "gemini": emit_gemini, "cursor": emit_cursor}


def main():
    global MODELS
    if not os.path.isdir(SRC):
        sys.exit(f"no canonical agents dir: {SRC}")
    MODELS = load_models()
    for d in OUT.values():
        os.makedirs(d, exist_ok=True)
    specs = sorted(f for f in os.listdir(SRC) if f.endswith(".md"))
    if not specs:
        sys.exit(f"no .md specs in {SRC}")
    # validate every spec before writing anything, so a bad tier cannot leave
    # a half-synced set of tools behind
    parsed = []
    for f in specs:
        name = f[:-3]
        path = os.path.join(SRC, f)
        meta, tools, body = parse(path)
        meta.setdefault("name", name)
        parsed.append((name, meta, tools, body, tier_of(meta, path)))
    for name, meta, tools, body, tier in parsed:
        routed = [t for t in EMITTERS if model_for(t, tier)]
        for tool, emit in EMITTERS.items():
            out = os.path.join(OUT[tool], f"{name}.md")
            open(out, "w", encoding="utf-8").write(emit(name, meta, tools, body, tier))
        where = ", ".join(routed) if routed else "none — inherits everywhere"
        print(f"  {name}: tier={tier or 'inherit'} -> pinned in {where}")
    print(f"Synced {len(specs)} agent(s) to {len(EMITTERS)} tools.")
    print("Codex CLI has no per-agent layer: set [agents].default_subagent_model "
          "in ~/.codex/config.toml.")


if __name__ == "__main__":
    main()
