---
name: memory-gc
description: Audit a memory directory (global ~/.agents/memory or a project's .agents/memory) for stale, duplicate, contradictory, or orphaned memories and propose cleanup — merge, update, or delete. Use when the user says "memory aufräumen", "memory-gc", "alte memories", or when a memory dir has visibly rotted (contradictions, many stale entries).
---

# Memory garbage collection

Audit one memory directory and propose cleanup. **Propose only — never delete
or merge without the user's explicit approval** (per AGENTS.md Selbstoptimierung).

## Procedure

1. **Scope:** default to the current project's `.agents/memory/`; audit
   `~/.agents/memory/` when asked or when no project applies.
2. **Consistency check** (mechanical):
   - Files without an index line in `MEMORY.md`; index lines without a file.
   - Broken `[[name]]` links (target slug does not exist — may also mark a
     memory worth writing; flag, don't auto-fix).
   - Files violating the format in `~/.agents/memory/README.md` (missing
     frontmatter, imperative phrasing instead of declarative facts).
3. **Content check** (read every file):
   - **Stale:** claims about files/entities/versions that no longer match
     reality — verify cheap claims (paths, entity names, flags) against the
     repo/system before flagging; expensive ones, flag as "verify".
   - **Superseded/contradictory:** a newer memory corrects an older one →
     merge into the newer, delete the older.
   - **Duplicates/overlap:** same fact in two files → merge.
   - **Session residue:** task progress, done-logs, one-off outcomes → delete
     (violates the "reduces future steering" rule).
4. **Propose:** one table — file → finding → action (KEEP / UPDATE / MERGE
   INTO x / DELETE) → one-line reason. Wait for approval.
5. **Apply** approved actions only: edit/delete files, update every affected
   `MEMORY.md` index line and `[[links]]`, report what changed.

## Never

- Never delete or merge before the user approved the proposal table.
- Never "improve" a memory's meaning while merging — preserve facts, dates,
  and the Why; only remove redundancy.
- Never touch memories of other projects than the audited directory.
