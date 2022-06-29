" General Settings {

set nocompatible            " disable compatibility to old-time vi

set title
set path+=**	            " Search down into subfolders, provides tab-completion
set wildmenu		        " Display all matching files when we tab complete

filetype plugin indent on   "allow auto-indenting depending on file type
filetype plugin on
syntax on                   " syntax highlighting

set mouse=a                  " mouse scrollingmode
set mousehide               " hide mouse pointer while typing

set clipboard=unnamed,unnamedplus " use system clipboard

set autochdir               " sets the working directory to the current file.

set history=1000            " Store a ton of history (default is 20)
set hidden                  " Allow buffer switch without saving

set showmatch               " show matching 
set hlsearch                " highlight search 
set incsearch               " incremental search


set showcmd                 " show current command
set showmode                " show current mode

set number                  " add line numbers
set relativenumber          " show line numbers relative to the curser position

set ignorecase              " case insensitive 
set smartcase		        " case insensitive as long as you dont use case sensitiv letter
set incsearch               " set incremental search

set scrolloff=5             " start scrolling the page when curseor is # lines from the edge

set encoding=utf-8

set complete+=kspell        " auto complete with spellcheck
set completeopt=menuone,longest " auto complete menu

set wildmode=longest,list   " get bash-like tab completions
set cc=80                   " set an 80 column border for good coding style
set mouse=a                 " enable mouse click
set clipboard=unnamedplus   " using system clipboard
set ttyfast                 " Speed up scrolling in Vim
" set spell                 " enable spell check (may need to download language package)
" set noswapfile            " disable creating swap file
"}


" Setting up the directories {
set backup                  " Backups are nice
set backupdir=~/.cache/vim  " Directory to store backup files in.
set undolevels=1000         " Maximum number of changes taht can be undone
set undoreload=10000        " Maximum numbers of lines to save for undo on a buffer reload
"}

" Formatting {
set wrap                    " wrapping long lines
set tabstop=2 softtabstop=2 " number of columns occupied by a tab 
set expandtab               " converts tabs to white space
set shiftwidth=2            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set smartindent             " attempts to properly indent
set pastetoggle=<F2>         " pastetoggle (sane indentation on pastes)
"}


" Vim UI{
" use the light solarize theme:
#set background=light

set cursorline              " highlight current cursorline

"}
"
" Set color theme
colorscheme dracula

" vim-plug
" https://github.com/junegunn/vim-plug 
call plug#begin()

Plug 'junegunn/vim-easy-align'      " Easy align everything
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } " Fuzzy Finder
Plug 'dense-analysis/ale'            " linting for a lot of languages
Plug 'Yggdroot/indentLine'           " indetion Marking Plugin

"Plug 'kyazdani42/nvim-web-devicons' " Recommended for coloured icons
"Plug 'akinsho/bufferlilne.nvim'     " bufferline with close icons
" Plug 'fatih/vim-go', { 'tag': '*' } " Development for go programms in vim

call plug#end()

" Setup for working with YAML files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab " Setup 2 spaces indention for YAML files


"let g:indentLine_char = '⦙'         " changing indent character

let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
let g:ale_lint_on_text_changed = 'never'    " only linting on save
