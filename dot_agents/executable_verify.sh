#!/usr/bin/env bash
# verify.sh — Prüft ob alle Symlinks und Verlinkungen korrekt sind.
#
# Usage:
#   ./verify.sh              alle installierten Clients prüfen
#   ./verify.sh <client>     nur einen Client prüfen
#
# Clients: claude, opencode, gemini, codex, pi
set -euo pipefail

AGENTS_DIR="${AGENTS_DIR:-$(cd "$(dirname "$0")" && pwd)}"
SKILLS_DIR="$AGENTS_DIR/skills"
AGENTS_FILE="$AGENTS_DIR/AGENTS.md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

OK=0
WARN=0
FAIL=0

ok()   { echo -e "  ${GREEN}OK${NC}  $1"; OK=$((OK + 1)); }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; WARN=$((WARN + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; FAIL=$((FAIL + 1)); }

# ── Prüfungen ───────────────────────────────────────────────────────────────

check_symlink() {
  local path="$1" expected_target="$2" label="$3"
  if [ ! -L "$path" ]; then
    if [ -f "$path" ]; then
      warn "$label: Datei existiert, ist aber kein Symlink"
    else
      fail "$label: fehlt"
    fi
    return
  fi
  local target
  target="$(readlink "$path")"
  if [ "$target" = "$expected_target" ]; then
    ok "$label symlink korrekt"
  else
    warn "$label zeigt auf $target (erwartet: $expected_target)"
  fi
  if [ ! -e "$path" ]; then
    fail "$label: Symlink hängt (Ziel existiert nicht)"
  fi
}

check_broken_symlink() {
  local path="$1" label="$2"
  if [ -L "$path" ] && [ ! -e "$path" ]; then
    fail "$label: Symlink hängt"
  fi
}

count_skills() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find -L "$dir" -maxdepth 2 -name "SKILL.md" -printf '%h\n' 2>/dev/null | wc -l
  else
    echo 0
  fi
}

count_skills_individual() {
  local dir="$1"
  local count=0
  if [ -d "$dir" ]; then
    for d in "$dir"/*/; do
      [ -d "$d" ] || continue
      [ -f "$d/SKILL.md" ] && count=$((count + 1))
    done
  fi
  echo "$count"
}

# ── Client-Checks ───────────────────────────────────────────────────────────

verify_claude() {
  echo ""
  echo "── Claude Code ──"
  local dir="$HOME/.claude"
  check_symlink "$dir/CLAUDE.md" "$AGENTS_FILE" "CLAUDE.md"
  check_symlink "$dir/skills" "$SKILLS_DIR" "skills/"

  if [ -d "$dir/agents" ]; then
    local count
    count="$(find "$dir/agents" -name '*.md' 2>/dev/null | wc -l)"
    if [ "$count" -gt 0 ]; then
      ok "agents/: $count Subagent-Dateien"
    else
      warn "agents/: Verzeichnis vorhanden aber leer"
    fi
  else
    warn "agents/: Verzeichnis fehlt (sync-agents.py ausführen)"
  fi
}

verify_opencode() {
  echo ""
  echo "── OpenCode ──"
  local dir="$HOME/.config/opencode"
  check_symlink "$dir/AGENTS.md" "$AGENTS_FILE" "AGENTS.md"

  if [ -d "$SKILLS_DIR" ]; then
    ok "Skills nativ lesbar aus $SKILLS_DIR"
  else
    fail "skills-Verzeichnis fehlt: $SKILLS_DIR"
  fi

  if [ -d "$dir/agent" ]; then
    local count
    count="$(find "$dir/agent" -name '*.md' 2>/dev/null | wc -l)"
    if [ "$count" -gt 0 ]; then
      ok "agent/: $count Subagent-Dateien"
    else
      warn "agent/: Verzeichnis vorhanden aber leer"
    fi
  else
    warn "agent/: Verzeichnis fehlt (sync-agents.py ausführen)"
  fi
}

verify_gemini() {
  echo ""
  echo "── Gemini CLI ──"
  local dir="$HOME/.gemini"
  local gemini_md="$dir/GEMINI.md"

  if [ -f "$gemini_md" ]; then
    if grep -qF "@$AGENTS_FILE" "$gemini_md"; then
      ok "GEMINI.md Import vorhanden"
    else
      fail "GEMINI.md: Import von AGENTS.md fehlt"
    fi
  else
    fail "GEMINI.md fehlt"
  fi

  check_symlink "$dir/skills" "$SKILLS_DIR" "skills/"

  if [ -d "$dir/agents" ]; then
    local count
    count="$(find "$dir/agents" -name '*.md' 2>/dev/null | wc -l)"
    if [ "$count" -gt 0 ]; then
      ok "agents/: $count Subagent-Dateien"
    else
      warn "agents/: Verzeichnis vorhanden aber leer"
    fi
  else
    warn "agents/: Verzeichnis fehlt (sync-agents.py ausführen)"
  fi
}

verify_codex() {
  echo ""
  echo "── Codex CLI ──"
  local dir="$HOME/.codex"
  check_symlink "$dir/AGENTS.md" "$AGENTS_FILE" "AGENTS.md"

  if [ -d "$dir/skills" ]; then
    local expected
    expected="$(count_skills "$SKILLS_DIR")"
    local actual
    actual="$(count_skills_individual "$dir/skills")"

    # Prüfe ob Skills hängen
    local broken=0
    for link in "$dir/skills"/*/; do
      [ -L "$link" ] && [ ! -e "$link" ] && broken=$((broken + 1))
    done

    if [ "$actual" -ge "$expected" ] && [ "$broken" -eq 0 ]; then
      ok "skills/: $actual/$expected Skills verlinkt"
    else
      warn "skills/: $actual/$expected Skills verlinkt, $broken hängen"
    fi
  else
    warn "skills/: Verzeichnis fehlt"
  fi
}

verify_pi() {
  echo ""
  echo "── Pi Agent ──"
  local dir="$HOME/.pi/agent"
  check_symlink "$dir/AGENTS.md" "$AGENTS_FILE" "AGENTS.md"

  if [ -d "$dir/skills" ]; then
    local expected
    expected="$(count_skills "$SKILLS_DIR")"
    local actual
    actual="$(count_skills_individual "$dir/skills")"

    local broken=0
    for link in "$dir/skills"/*/; do
      [ -L "$link" ] && [ ! -e "$link" ] && broken=$((broken + 1))
    done

    if [ "$actual" -ge "$expected" ] && [ "$broken" -eq 0 ]; then
      ok "skills/: $actual/$expected Skills verlinkt"
    else
      warn "skills/: $actual/$expected Skills verlinkt, $broken hängen"
    fi
  else
    warn "skills/: Verzeichnis fehlt"
  fi
}

# ── Verfügbare Clients ermitteln ────────────────────────────────────────────

detect_clients() {
  local clients=()
  [ -d "$HOME/.claude" ] && clients+=(claude)
  [ -d "$HOME/.config/opencode" ] && clients+=(opencode)
  [ -d "$HOME/.gemini" ] && clients+=(gemini)
  [ -d "$HOME/.codex" ] && clients+=(codex)
  [ -d "$HOME/.pi/agent" ] && clients+=(pi)
  echo "${clients[@]}"
}

# ── Hauptprogramm ───────────────────────────────────────────────────────────

main() {
  echo "═══════════════════════════════════════════"
  echo "  Agent Setup — Verifikation"
  echo "═══════════════════════════════════════════"

  if [ ! -d "$SKILLS_DIR" ]; then
    fail "skills-Verzeichnis nicht gefunden: $SKILLS_DIR"
    exit 1
  fi

  local total_skills
  total_skills="$(count_skills "$SKILLS_DIR")"
  echo ""
  echo "  Canonical Skills: $total_skills in $SKILLS_DIR"

  local client="${1:-}"

  if [ -n "$client" ]; then
    case "$client" in
      claude)   verify_claude ;;
      opencode) verify_opencode ;;
      gemini)   verify_gemini ;;
      codex)    verify_codex ;;
      pi)       verify_pi ;;
      *)
        echo "Unbekannter Client: $client"
        echo "Verfügbare Clients: claude, opencode, gemini, codex, pi"
        exit 1
        ;;
    esac
  else
    local detected
    detected="$(detect_clients)"
    if [ -z "$detected" ]; then
      warn "Keine Client-Verzeichnisse gefunden"
      exit 0
    fi
    for c in $detected; do
      case "$c" in
        claude)   verify_claude ;;
        opencode) verify_opencode ;;
        gemini)   verify_gemini ;;
        codex)    verify_codex ;;
        pi)       verify_pi ;;
      esac
    done
  fi

  echo ""
  echo "═══════════════════════════════════════════"
  echo -e "  Ergebnis: ${GREEN}$OK OK${NC}  ${YELLOW}$WARN WARN${NC}  ${RED}$FAIL FAIL${NC}"
  echo "═══════════════════════════════════════════"

  [ "$FAIL" -gt 0 ] && exit 1
  exit 0
}

main "$@"
