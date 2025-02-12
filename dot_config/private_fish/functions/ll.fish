function ll --wraps=ls --description 'List contents of directory using long format'
    eza -bl --git --icons --time-style long-iso --group-directories-first $argv
end
