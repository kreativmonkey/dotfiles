function ssh --description 'Wrapper for kitty ssh kitten'
    switch "$TERM"
        case xterm-kitty
            kitty +kitten ssh $argv
        case wezterm
            wezterm ssh $argv
        case '*'
            command ssh $argv
    end
end
