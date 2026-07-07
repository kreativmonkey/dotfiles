# flake.nix devShell recipes

Per-language starting points for `devShells.default`. Adapt package lists to what
stack detection (SKILL.md step A) actually found — these are skeletons, not fixed
menus. All version numbers below are EXAMPLES: always match what the project
declares and verify the attribute exists (SKILL.md step C).

## Base skeleton (any language — copy this, fill in packages)

No `flake-utils`: `nixpkgs.lib.genAttrs` does the same without an extra input.

```nix
{
  description = "<project> dev environment";

  # branch from SKILL.md step B — do not copy this version blindly
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            # toolchain + package manager + test framework + CI tools go here
            just
          ];
          shellHook = ''echo "dev shell ready — run \`just\`"'';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
```

## Rust (pinned toolchain via rust-overlay)

```nix
inputs.rust-overlay.url = "github:oxalica/rust-overlay";
# in outputs: add rust-overlay to the function args, then per system:
let
  pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlays.default ]; };
  rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml; # or .stable.latest.default
in
pkgs.mkShell {
  packages = with pkgs; [
    rust cargo-nextest
    pkg-config openssl   # common native deps — only if the build needs them
    just
  ];
}
```

`clippy`/`rustfmt` are included in the overlay toolchain. Without a toolchain file,
use `pkgs.rust-bin.stable.latest.default`.

## Node / TypeScript (pin Node major; match the lockfile's package manager)

```nix
packages = with pkgs; [
  nodejs_22          # match package.json "engines" / .nvmrc
  pnpm               # or yarn / bun; npm ships with nodejs
  just
];
```

Test/CI tools (vitest, jest, eslint, prettier, tsc) come from the project's own
`node_modules`; the justfile runs them via `pnpm exec …`. Do not add them to the
flake.

## Python (uv or poetry; pin the interpreter)

```nix
packages = with pkgs; [
  python313          # match .python-version / pyproject requires-python
  uv                 # or poetry — match the lockfile
  ruff               # only if not already a project dev-dependency
  just
];
```

`pytest`/`mypy`/`pyright` live in the project venv; the justfile invokes them via
`uv run` / `poetry run`.

## Go

```nix
packages = with pkgs; [
  go_1_24            # match the toolchain line in go.mod
  gopls gotools
  golangci-lint      # the typical CI gate
  just
];
```

Tests run via `go test ./...` (no extra package).

## Polyglot / monorepo

Combine the relevant package sets into one `mkShell`. If sub-projects need isolated
toolchains, expose multiple shells (`devShells.<system>.frontend`, `….backend`) and
let the justfile select: `nix develop .#frontend --command …`.

## Optional: meaningful `nix flake check`

The check runs in the Nix sandbox: **no network, no project dependency downloads** —
so full test suites and dependency-fetching builds do NOT work here. Wire only
hermetic, fast gates (format/lint of the tree) and leave tests to `just test`/CI:

```nix
checks = forAllSystems (pkgs: {
  fmt = pkgs.runCommand "fmt-check" { buildInputs = [ pkgs.nixfmt-rfc-style ]; } ''
    nixfmt --check ${self}/flake.nix && touch $out
  '';
});
```

## Complete justfile example (adapt commands to the detected stack)

```just
# show available recipes
default:
    @just --list

# install/sync dependencies
setup:
    pnpm install --frozen-lockfile

# start the dev server
dev:
    pnpm exec vite

test:
    pnpm exec vitest run

lint:
    pnpm exec eslint .

fmt:
    pnpm exec prettier --write .

fmt-check:
    pnpm exec prettier --check .

typecheck:
    pnpm exec tsc --noEmit

# local mirror of CI
check: fmt-check lint typecheck test
```
