function ll --wraps=ls --description 'List contents of directory using long format'
    eza -blh --git --icons=auto --group-directories-first $argv
end
