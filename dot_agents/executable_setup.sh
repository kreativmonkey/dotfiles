#!/usr/bin/env bash
# setup.sh — Client-spezifische Verlinkungen für das Agent-Setup herstellen.
#
# Usage:
#   ./setup.sh              interaktives Menu
#   ./setup.sh <client>     direkt für einen Client
#   ./setup.sh all          alle Clients
#
# Clients: claude, opencode, gemini, codex, pi
set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SKILLS_DIR="$AGENTS_DIR/skills"
AGENTS_FILE="$AGENTS_DIR/AGENTS.md"
SYNC_SCRIPT="$AGENTS_DIR/sync-agents.py"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}OK${NC}  $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; }

# ── Hilfsfunktionen ─────────────────────────────────────────────────────────

ensure_dir() {
  mkdir -p "$1" 2>/dev/null
}

link_file() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    local target
    target="$(readlink "$dst")"
    if [ "$target" = "$src" ]; then
      ok "$(basename "$dst") bereits korrekt verlinkt"
      return
    fi
    warn "$(basename "$dst") zeigt auf $target — überschreibe"
  fi
  ln -sfn "$src" "$dst"
  ok "$(basename "$dst") -> $src"
}

link_skills_dir() {
  local dst="$1"
  ensure_dir "$dst"
  ln -sfn "$SKILLS_DIR" "$dst/skills"
  ok "skills/ Verzeichnis-Symlink -> $SKILLS_DIR"
}

link_skills_individual() {
  local dst="$1"
  ensure_dir "$dst/skills"
  local count=0
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    local name
    name="$(basename "$d")"
    if [ ! -e "$dst/skills/$name" ]; then
      ln -sfn "$(realpath "$d")" "$dst/skills/$name"
      count=$((count + 1))
    fi
  done
  ok "$count Skills einzeln verlinkt in $dst/skills/"
}

# ── Client-Setup Funktionen ─────────────────────────────────────────────────

setup_claude() {
  echo ""
  echo "── Claude Code ──"
  local dir="$HOME/.claude"
  ensure_dir "$dir"
  link_file "$AGENTS_FILE" "$dir/CLAUDE.md"
  link_skills_dir "$dir"
}

setup_opencode() {
  echo ""
  echo "── OpenCode ──"
  local dir="$HOME/.config/opencode"
  ensure_dir "$dir"
  link_file "$AGENTS_FILE" "$dir/AGENTS.md"
  # OpenCode liest ~/.agents/skills nativ — kein Symlink nötig
  ok "OpenCode liest Skills aus $SKILLS_DIR (nativer Zugriff)"
}

setup_gemini() {
  echo ""
  echo "── Gemini CLI ──"
  local dir="$HOME/.gemini"
  ensure_dir "$dir"

  local gemini_md="$dir/GEMINI.md"
  local import_line="@$AGENTS_FILE"

  if [ -f "$gemini_md" ]; then
    if grep -qF "$import_line" "$gemini_md"; then
      ok "GEMINI.md Import bereits vorhanden"
    else
      warn "GEMINI.md existiert — Import wird vorangestellt"
      local tmp
      tmp="$(mktemp)"
      { echo "$import_line"; cat "$gemini_md"; } > "$tmp"
      mv "$tmp" "$gemini_md"
      ok "Import zu GEMINI.md hinzugefügt"
    fi
  else
    echo "$import_line" > "$gemini_md"
    ok "GEMINI.md erstellt mit Import"
  fi

  link_skills_dir "$dir"
}

setup_codex() {
  echo ""
  echo "── Codex CLI ──"
  local dir="$HOME/.codex"
  ensure_dir "$dir"
  link_file "$AGENTS_FILE" "$dir/AGENTS.md"
  # Codex: Einzel-Symlinks — .system/ darf nicht überschrieben werden
  link_skills_individual "$dir"
}

setup_pi() {
  echo ""
  echo "── Pi Agent ──"
  local dir="$HOME/.pi/agent"
  ensure_dir "$dir"
  link_file "$AGENTS_FILE" "$dir/AGENTS.md"
  link_skills_individual "$dir"
}

# ── Subagents generieren ────────────────────────────────────────────────────

sync_agents() {
  echo ""
  if [ -f "$SYNC_SCRIPT" ]; then
    python3 "$SYNC_SCRIPT"
  else
    warn "sync-agents.py nicht gefunden — überspringe Subagent-Generierung"
  fi
}

# ── Interaktives Menu ───────────────────────────────────────────────────────

show_menu() {
  echo ""
  echo "╔══════════════════════════════════════╗"
  echo "║  Agent Setup — Client auswählen      ║"
  echo "╠══════════════════════════════════════╣"
  echo "║  1) Claude Code                      ║"
  echo "║  2) OpenCode                         ║"
  echo "║  3) Gemini CLI                       ║"
  echo "║  4) Codex CLI                        ║"
  echo "║  5) Pi Agent                         ║"
  echo "║  6) Alle Clients                     ║"
  echo "║  q) Beenden                          ║"
  echo "╚══════════════════════════════════════╝"
  echo ""
  read -rp "Auswahl: " choice
  case "$choice" in
    1) setup_claude ;;
    2) setup_opencode ;;
    3) setup_gemini ;;
    4) setup_codex ;;
    5) setup_pi ;;
    6) setup_claude; setup_opencode; setup_gemini; setup_codex; setup_pi ;;
    q|Q) echo "Abgebrochen."; exit 0 ;;
    *) echo "Ungültige Auswahl."; exit 1 ;;
  esac
}

# ── Hauptprogramm ───────────────────────────────────────────────────────────

main() {
  if [ ! -d "$SKILLS_DIR" ]; then
    fail "skills-Verzeichnis nicht gefunden: $SKILLS_DIR"
    exit 1
  fi

  if [ ! -f "$AGENTS_FILE" ]; then
    fail "AGENTS.md nicht gefunden: $AGENTS_FILE"
    exit 1
  fi

  local client="${1:-}"

  case "$client" in
    claude)   setup_claude ;;
    opencode) setup_opencode ;;
    gemini)   setup_gemini ;;
    codex)    setup_codex ;;
    pi)       setup_pi ;;
    all)      setup_claude; setup_opencode; setup_gemini; setup_codex; setup_pi ;;
    "")       show_menu ;;
    *)
      echo "Unbekannter Client: $client"
      echo "Verfügbare Clients: claude, opencode, gemini, codex, pi, all"
      exit 1
      ;;
  esac

  sync_agents

  echo ""
  echo "── Fertig ──"
  echo "Änderungen sind sofort wirksam (Symlinks)."
  echo "Bei neuen Skills: ./setup.sh nochmal ausführen."
}

main "$@"
