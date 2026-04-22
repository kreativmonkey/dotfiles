function ssh --description 'Wrapper for kitty ssh kitten'
    if test "$TERM" = xterm-kitty
        kitty +kitten ssh $argv
    else
        command ssh $argv
    end
end
