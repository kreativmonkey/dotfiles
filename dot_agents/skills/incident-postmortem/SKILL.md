---
name: incident-postmortem
description: After an incident, outage, or tricky debugging session is resolved, capture it durably — symptom, root cause, fix, open items — as a project memory, plus an ADR when an architecture decision was made. Use when the user says "postmortem", "halte das fest", "schreib das auf", or right after a non-trivial root cause was found and fixed.
---

# Incident postmortem

Turn a finished debugging session into durable knowledge. Do this while the
session context is still available — not from memory in a later session.

## Procedure

1. **Reconstruct from the session** (not from imagination):
   - Symptom as first observed; affected systems/services.
   - Root cause with the decisive evidence (the one log line / config diff /
     command output that proved it).
   - Fix applied, and what was deliberately NOT done.
   - Open items / follow-ups (unfixed root causes elsewhere, tickets to open).
2. **Write the memory** into the affected project's `.agents/memory/`
   (cross-project incidents → global `~/.agents/memory/`). Follow
   `~/.agents/memory/README.md`; usually `type: project` with **Why** /
   **How to apply**. Include absolute dates. Link related memories with
   `[[name]]`. Add the `MEMORY.md` index line.
3. **Check for a superseded memory:** if an older memory described the broken
   state or a wrong theory, update or delete it — don't leave contradictions.
4. **ADR** — only if an architecture-level decision was made (storage layout,
   topology, dependency choice): record it via codebase-memory `manage_adr`
   in the affected repo, one decision per ADR with context and consequences.
5. **Self-optimization hook:** if the debugging revealed a reusable workflow
   or a gap in an existing skill, apply AGENTS.md § Selbstoptimierung —
   propose the skill / patch factual rot.
6. **Report:** where the memory/ADR was written, what was updated or deleted.

## Quality bar

- Declarative facts, not instructions to yourself.
- The test for every sentence: does it spare a future session a repeat
  diagnosis or a user correction? If not, cut it.
- Root cause ≠ symptom: "iSCSI timeouts" is a symptom; "single TrueNAS backs
  all stateful workloads and self-reports healthy while failing" is a cause.
