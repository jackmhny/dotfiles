:set number
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4

let $BASH_ENV = "~/.bash_aliases"

" For vimtex, conceal and hide the Conceal group highlighting
:set conceallevel=2
:highlight clear Conceal

"Changing default NERDTree arrows
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

nnoremap <C-t> :NERDTreeToggle<CR>

" Plug installs
call plug#begin('~/.local/share/nvim/plugged')
	Plug 'goolord/alpha-nvim'

	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'

	Plug 'preservim/nerdtree'

	" Plug 'itchyny/vim-cursorword'
	Plug 'tpope/vim-surround'
	Plug 'tpope/vim-commentary'

	Plug 'lervag/vimtex'

	Plug 'rust-lang/rust.vim'

	Plug 'vim-syntastic/syntastic'
call plug#end()

