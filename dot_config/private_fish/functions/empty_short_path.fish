function shorten_path
    # 1. Heimatverzeichnis durch ~ ersetzen
    set -l org_path (string replace -r "^$HOME" "~" $PWD)
    set -l git_base ""
    set -l main_git_base ""

    # 2. Prüfen, ob wir in einem Git-Repo oder Worktree sind
    if command git rev-parse --show-toplevel >/dev/null 2>&1
        set -l git_root (command git rev-parse --show-toplevel)
        set git_base (basename $git_root)

        set -l main_git_root (command git worktree list 2>/dev/null | head -n 1 | awk '{print $1}')
        if test -n "$main_git_root"
            set main_git_base (basename $main_git_root)
        end
    end

    # 3. Pfad in einzelne Ordner (Segmente) aufteilen
    set -l segments (string split / $org_path)
    set -l result_segments

    # Behandelt absolute Pfade außerhalb von $HOME (diese fangen mit / an, split erzeugt ein leeres erstes Element)
    set -l start_idx 1
    if test -z "$segments[1]"
        set -a result_segments ""
        set start_idx 2
    end

    set -l num_segments (count $segments)
    set -l i $start_idx
    # Den letzten Ordner lassen wir in der Schleife aus, damit er voll ausgeschrieben bleibt
    set -l last_idx (math $num_segments - 1)

    # 4. Segmente durchlaufen und kürzen
    while test $i -le $last_idx
        # Pfad testweise zusammenbauen, um die verbleibende Gesamtlänge zu prüfen
        set -l current_reconstructed (string join / $result_segments $segments[$i..-1])

        if test (string length "$current_reconstructed") -le 20
            break # Wenn der Pfad 20 Zeichen oder kürzer ist, den Rest nicht mehr anfassen
        end

        set -l segment $segments[$i]

        # Wenn das Segment das Git-Basis-Verzeichnis oder Haupt-Git-Verzeichnis ist, NICHT kürzen
        if test "$segment" = "$git_base" -o "$segment" = "$main_git_base"
            set -a result_segments $segment
        else
            # Auf ersten Buchstaben (oder Punkt + ersten Buchstaben bei versteckten Ordnern) kürzen
            set -l first_char (string match -r '^\.?.' "$segment")
            if test -z "$first_char"
                set first_char $segment
            end
            set -a result_segments $first_char
        end

        set i (math $i + 1)
    end

    # 5. Verbleibende, nicht bearbeitete Segmente (inkl. dem letzten Ordner) ans Ende anhängen
    set -l remaining_start (math (count $result_segments) + 1)
    if test $remaining_start -le $num_segments
        set -a result_segments $segments[$remaining_start..-1]
    end

    # 6. Den fertigen Pfad mit / verbinden und ausgeben
    string join / $result_segments
end
