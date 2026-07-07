#!/usr/bin/env bash
# Verlinkt das Claude-Code-Memory eines Projekts nach <projekt>/.agents/memory,
# damit alle CLI-Agenten (Claude Code, OpenCode, Gemini) dasselbe Memory teilen.
#
# Usage: link-project-memory.sh [projektpfad] [memory-quelle]
#   projektpfad:   Default aktuelles Verzeichnis
#   memory-quelle: anderes Projekt, dessen .agents/memory geteilt werden soll —
#                  z. B. der Haupt-Checkout, wenn projektpfad ein Worktree ist.
#                  Default: projektpfad selbst.
#
# - Existiert unter ~/.claude/projects/<munged>/memory schon ein echtes
#   Verzeichnis, werden dessen Dateien ins Ziel übernommen
#   (MEMORY.md-Index wird zeilenweise dedupliziert gemergt) und durch einen
#   Symlink ersetzt.
# - Ist das Projekt ein Git-Repo, wird `.agents/` in .git/info/exclude
#   eingetragen (lokal, kein Commit), sofern .agents nicht bereits getrackt ist.
set -euo pipefail

proj="$(realpath "${1:-$PWD}")"
memsrc="$(realpath "${2:-$proj}")"
munged="${proj//\//-}"
munged="${munged//./-}"
claude_dir="$HOME/.claude/projects/$munged/memory"
target="$memsrc/.agents/memory"

mkdir -p "$target"

if [ -L "$claude_dir" ]; then
    echo "schon verlinkt: $claude_dir -> $(readlink "$claude_dir")"
else
    if [ -d "$claude_dir" ]; then
        for f in "$claude_dir"/* "$claude_dir"/.[!.]*; do
            [ -e "$f" ] || continue
            base="$(basename "$f")"
            if [ "$base" = "MEMORY.md" ] && [ -f "$target/MEMORY.md" ]; then
                cat "$target/MEMORY.md" "$f" | awk 'NF && !seen[$0]++' > "$target/MEMORY.md.tmp"
                mv "$target/MEMORY.md.tmp" "$target/MEMORY.md"
                rm "$f"
            elif [ -e "$target/$base" ] && ! cmp -s "$f" "$target/$base"; then
                echo "WARNUNG: $base existiert im Ziel mit anderem Inhalt — als $base.migrated abgelegt"
                mv "$f" "$target/$base.migrated"
            else
                mv -f "$f" "$target/$base"
            fi
        done
        rmdir "$claude_dir"
    fi
    mkdir -p "$(dirname "$claude_dir")"
    ln -s "$target" "$claude_dir"
    echo "verlinkt: $claude_dir -> $target"
fi

if [ "$memsrc" = "$proj" ] && git -C "$proj" rev-parse --git-dir >/dev/null 2>&1; then
    if [ -z "$(git -C "$proj" ls-files .agents 2>/dev/null)" ]; then
        exclude_file="$(git -C "$proj" rev-parse --git-path info/exclude)"
        # git-path liefert ggf. relative Pfade (relativ zum Repo)
        case "$exclude_file" in
            /*) : ;;
            *) exclude_file="$proj/$exclude_file" ;;
        esac
        if ! grep -qxF '.agents/' "$exclude_file" 2>/dev/null; then
            mkdir -p "$(dirname "$exclude_file")"
            echo '.agents/' >> "$exclude_file"
            echo "git-exclude ergänzt: $exclude_file"
        fi
    else
        echo "Hinweis: .agents ist in diesem Repo getrackt — kein exclude gesetzt"
    fi
fi
