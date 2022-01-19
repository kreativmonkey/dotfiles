function la --wraps=ls --description 'List contents of directory, including hidden files in directory using long format'
    exa -lbhHigUmuSa --time-style=long-iso --git --color-scale $argv
end
