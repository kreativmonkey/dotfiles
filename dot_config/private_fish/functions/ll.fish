function ll --wraps=ls --description 'List contents of directory using long format'
    exa -lh --icons --header --git $argv
end
