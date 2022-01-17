function gpsup --description 'Shortcut pushing current branch and set upstream'
    git_is_repo; and begin
        git_branch_name | git push --set-upstream origin
    end
end
