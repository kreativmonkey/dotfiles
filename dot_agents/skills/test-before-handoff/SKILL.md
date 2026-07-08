---
name: test-before-handoff
description: Verify that developed code actually runs before handing it back to the user — never deliver code proven only by reading it. Use whenever you write or change code (a feature, bugfix, refactor, integration, script) and are about to report it as done. Triggers on "fertig", "erledigt", "das sollte funktionieren", "kannst du testen", or any moment you're about to claim code works. Especially for code using external frameworks/APIs (Home Assistant, aiohttp, Django, cloud SDKs) whose signatures only fail at runtime.
---

# Test before handoff

**The rule: code is not "done" until it has been executed in an environment that can
import its real dependencies.** Reading code, `py_compile`, and type-guessing are NOT
verification — they miss exactly the failures that reach the user: wrong API
signatures, renamed kwargs, strict decoders, import errors, wrong assumptions about a
library's behavior.

If you are about to write "fertig", "sollte jetzt funktionieren", or hand code back:
stop and work this checklist first. If you genuinely cannot run it, say so **loudly**
and list what is unverified — do not imply it works.

## Checklist

1. **Is there a runnable environment?** Can you import the code's real dependencies
   (the framework, HTTP client, SDK)?
   - No → build one first. Invoke the **`nix-dev-env`** skill to get a `flake.nix` +
     `justfile`; install framework-specific test deps (often PyPI-only, e.g.
     `pytest-homeassistant-custom-component`) into a `.venv` via `uv`. This is not
     optional overhead — it is what makes verification possible at all.
   - Yes → use it.

2. **Pick the right level of "tested" for the change** (do the cheapest that actually
   exercises the changed path):
   - Pure logic (parsers, crypto, formatting) → unit test with a known-answer or
     round-trip assertion.
   - Framework integration (config flows, handlers, endpoints, models) → a test that
     drives the real framework (e.g. HA's `pytest-homeassistant-custom-component`), so
     signature/contract mismatches surface.
   - App/CLI/service behavior → actually run it (see the **`run`** / **`verify`**
     skills) and observe the real output, not a dry run.
   - External I/O you can't hit → mock the transport (`aioresponses`, `respx`,
     `requests-mock`) and assert the request/response handling.

3. **Write the test to fail on the bug you're fixing.** A bugfix ships with a test
   that would have caught it. A feature ships with a test that exercises its main path
   and at least one error path.

4. **Run it and read the output.** Green means green — paste/relay the actual result.
   Also run the project's lint/format gate (`just check` if present) so you don't hand
   over code that fails CI.

5. **Regressions:** when a bug slips through to the user anyway, add a test that
   reproduces it *before* fixing — then fix — so it can't return.

## Reporting

- State plainly what you ran and what passed ("12 tests grün, lint sauber").
- Separate **verified** from **unverified**: if the network/hardware path was only
  checked live or not at all, name it explicitly and offer to cover it (e.g. with
  mocked transport). Never let "I read it and it looks right" masquerade as tested.

## Never

- Never report code as working based only on static reading, `py_compile`, or "it
  should…". That is the exact failure mode this skill exists to prevent.
- Never skip building a test env because it "looks like a one-liner" — the one-liners
  (`get_url(prefer_internal=…)`, `resp.text()` on non-UTF-8) are what break.
- Never leave the user to be your test runner for things you could have run yourself.
