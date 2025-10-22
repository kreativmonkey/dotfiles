function ff --wraps=fzf --description 'Preconfigured fzf command to search in files'
    fzf --preview 'bat --style=numbers --color=always {}'
end
