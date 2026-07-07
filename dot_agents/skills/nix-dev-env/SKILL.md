---
name: nix-dev-env
description: Generate a Nix flake dev environment (flake.nix) and a justfile for the currently opened project — detecting the language, dependencies, pinned versions, test frameworks, and CI/pipeline tooling. Use when the user wants to set up a reproducible dev shell, "nix flake", "nix develop", a justfile, or onboard a project to the standard Nix+just workflow.
---

# Nix dev environment + justfile

Set up a reproducible developer environment for the opened project: a `flake.nix`
exposing a `devShell` with every tool the project actually needs, plus a `justfile`
that wraps the common tasks. Goal: `nix develop` drops the user into a shell where
`just` lists everything they can run.

This skill writes real files into the project and then verifies they evaluate.
Do not hand back untested output.

## Checklist (work through in order)

1. Existing `flake.nix`/`justfile`? → merge into it, show a diff before overwriting.
2. Detect the stack (step A) — read files, do not guess.
3. Determine the current nixpkgs stable branch (step B).
4. Write `flake.nix` from [flake-recipes.md](flake-recipes.md) (step C).
5. Write the `justfile` (step D).
6. `git add` the new files, then verify (step E). Fix and re-run until green.
7. Report: what was detected, what was pinned, verification output. Remind the
   user to commit `flake.lock`.

## A. Detect the stack (do this first, do not guess)

Look for, in roughly this order:

- **Language & toolchain version** — `rust-toolchain.toml`/`Cargo.toml`, `package.json`
  (`engines`, `packageManager`), `.nvmrc`, `go.mod`, `pyproject.toml`/`.python-version`,
  `*.csproj`, `pom.xml`/`build.gradle`, `Gemfile`, `mix.exs`, etc.
- **Package manager** — the lockfile decides: `Cargo.lock`, `pnpm-lock.yaml`/
  `package-lock.json`/`yarn.lock`/`bun.lockb`, `uv.lock`/`poetry.lock`, `go.sum`.
- **Test framework** — from deps/config: cargo test/nextest, vitest/jest, pytest,
  `go test`, rspec, … The dev shell must contain whatever runs the tests.
- **CI / pipeline tooling** — read `.github/workflows/*`, `.gitlab-ci.yml`, `.forgejo/`,
  `Makefile`, existing `justfile`/`Taskfile`. Every tool CI invokes (linter, formatter,
  type checker, coverage, build, container build) belongs in the dev shell so local == CI.
- **Extra runtime deps** — databases, `protoc`, `openssl`, `pkg-config`, system libs
  referenced by build scripts or native modules.

Pin the toolchain to the version the project declares. If none is declared, use the
current stable from nixpkgs and say so. If the language or version is genuinely
ambiguous and the choice changes the flake, ask the user.

## B. Determine the current nixpkgs stable branch

Do not hard-code a release from memory — look it up:

```bash
git ls-remote --heads https://github.com/NixOS/nixpkgs 'refs/heads/nixos-*' \
  | grep -oE 'nixos-[0-9]+\.[0-9]+$' | sort -V | tail -1
```

Use that branch (e.g. `github:NixOS/nixpkgs/nixos-25.11`) for `inputs.nixpkgs`.
Use `nixpkgs-unstable` only if the project needs a package/version stable lacks —
and say so.

## C. Write flake.nix

Copy the base skeleton from [flake-recipes.md](flake-recipes.md) and fill in the
package list; per-language recipes (Rust, Node, Python, Go, polyglot) are there too.

Requirements:
- `inputs.nixpkgs` pinned to the branch from step B. No extra inputs unless needed
  (e.g. `rust-overlay` for pinned Rust toolchains).
- `devShells.default` with: toolchain, package manager, **test framework**, **all CI
  tools**, and `just`.
- `shellHook` printing a one-line hint (in the skeleton).
- `formatter` set to `nixfmt-rfc-style` (in the skeleton), so `nix fmt` works.
- **Verify every package attribute you are not 100% sure of** before relying on it:
  `nix eval github:NixOS/nixpkgs/<branch>#<attr>.name` — if it errors, search the
  real name with `nix search nixpkgs <term>`. Never invent attribute names.

## D. Write the justfile

The default recipe (bare `just`) MUST show the command overview:

```just
# show available recipes
default:
    @just --list
```

Derive the remaining recipes from what the project actually has — only include what
applies, wired to the project's real commands: `setup`, `run`/`dev`, `test`, `lint`,
`fmt` (+ `fmt-check`), `typecheck`, `build`, `check` (composite:
`check: fmt-check lint typecheck test` — the local mirror of CI), `ci`.

Keep recipes thin: each calls the underlying tool, no hidden logic. Use recipe
dependencies instead of duplicating commands. A complete example is at the end of
[flake-recipes.md](flake-recipes.md).

## E. Verify before finishing

```bash
git add flake.nix justfile        # flakes only see git-tracked files!
nix flake check                   # add --no-build if a full build is too heavy — say so
nix develop --command just --list # proves the shell builds and just works
```

Both commands must pass before reporting success. Common failures:

| Error | Cause | Fix |
|---|---|---|
| `path '…' does not contain a 'flake.nix'` or new file "not found" | file not git-tracked | `git add` it |
| `attribute '<x>' missing` | invented/renamed package attr | `nix search nixpkgs <term>`, use the real name |
| `experimental Nix feature 'flakes' is disabled` | flakes not enabled | append `--extra-experimental-features 'nix-command flakes'` |
| hash/lock mismatch after editing inputs | stale `flake.lock` | `nix flake update <input>` |

If Nix is unavailable in this environment, say so explicitly and give the user the
two verification commands to run.

## Never

- Never overwrite an existing `flake.nix`/`justfile` without showing a diff and
  confirming — merge instead when sensible.
- Never invent package attribute names — verify per step C.
- Never install project tooling globally (`apt`/`brew`/`pip -g`) — everything goes
  through the dev shell.
- Never put lockfile-managed dev deps (eslint, vitest, pytest, mypy, …) into the
  flake when the project's package manager provides them — the justfile calls them
  via `pnpm exec` / `uv run` / `poetry run`.
- Never leave `flake.lock` uncommitted — it IS the reproducibility.

## Conventions

- Add `.direnv/` to `.gitignore`; offer a `.envrc` containing `use flake` for
  direnv users if they want auto-loading.
