set nocompatible            " disable compatibility to old-time vi

set title
set path+=**	            " Search down into subfolders, provides tab-completion
set wildmenu		    " Display all matching files when we tab complete

set showmatch               " show matching 
set mouse=a                 " mouse scrollingmode
set hlsearch                " highlight search 
set incsearch               " incremental search

set tabstop=4 softtabstop=4 " number of columns occupied by a tab 
set expandtab               " converts tabs to white space
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set smartindent             " attempts to properly indent

set showcmd                 " show current command
set showmode                " show current mode

filetype plugin on
syntax on                   " syntax highlighting

set number                  " add line numbers
set relativenumber          " show line numbers relative to the curser position

set nowrap                  " does not allow lines to wrap
set ignorecase              " case insensitive 
set smartcase		    " case insensitive as long as you dont use case sensitiv letter
set incsearch               " set incremental search

set scrolloff=5             " start scrolling the page when curseor is # lines from the edge

set encoding=utf-8

set complete+=kspell        " auto complete with spellcheck
set completeopt=menuone,longest " auto complete menu

set wildmode=longest,list   " get bash-like tab completions
set cc=80                  " set an 80 column border for good coding style
filetype plugin indent on   "allow auto-indenting depending on file type
set mouse=a                 " enable mouse click
set clipboard=unnamedplus   " using system clipboard
set cursorline              " highlight current cursorline
set ttyfast                 " Speed up scrolling in Vim
" set spell                 " enable spell check (may need to download language package)
" set noswapfile            " disable creating swap file
set backupdir=~/.cache/vim " Directory to store backup files.

" Set color theme
colorscheme dracula
