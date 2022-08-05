if status is-interactive
    # Commands to run in interactive sessions can go here
end
if test -e /usr/bin/mcfly
  mcfly init fish | source
end
# Includes Zoxide for fast cd commands
if test -e /usr/bin/zoxide
  zoxide init fish | source
end

if test -e /usr/bin/fzf
  fzf_configure_bindings --history=\cs

  if test -e /usr/bin/exa
    set fzf_preview_dir_cmd exa --all --color=always --icons
  end
end
