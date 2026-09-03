{ inputs, ... }:

{
  perSystem = { pkgs, ... }:
    {
      packages.myVim = inputs.wrapper-modules.wrappers.vim.wrap {
        inherit pkgs;

        plugins = with pkgs.vimPlugins; [
          catppuccin-vim
          nerdtree
          vim-airline
          vim-airline-themes
          fzf-vim
          auto-pairs
        ];

        vimrc = ''
          " =============================================================================
          " CONFIGURAÇÕES VISUAIS E DE TEMA
          " =============================================================================
          syntax on
          set termguicolors
          colorscheme catppuccin_mocha
          let g:airline_theme = 'catppuccin_mocha'

          set number
          set relativenumber
          set cursorline
          set noshowmode
          set splitbelow
          set splitright

          " CONFIGURAÇÃO DO EXPLORADOR (NERDTree)
          let g:NERDTreeWinPos = "right"
          set scrolloff=10

          " =============================================================================
          " COMPORTAMENTO E NAVEGAÇÃO
          " =============================================================================
          set mouse=a
          set hidden
          set wildmenu
          set showcmd
          set clipboard=unnamedplus
          set autoindent
          set smartindent
          set updatetime=300
          set wrap
          set linebreak

          " =============================================================================
          " BUSCA (SEARCH)
          " =============================================================================
          set hlsearch
          set incsearch
          set ignorecase
          set smartcase

          " =============================================================================
          " ARQUIVOS E BACKUP (LIMPEZA)
          " =============================================================================
          set noswapfile
          set nobackup
          set nowritebackup

          " =============================================================================
          " ATALHOS DE TECLADO (MAPPINGS)
          " =============================================================================
          " Ctrl + e: Abre ou fecha o explorador de arquivos (NERDTree)
          nnoremap <C-e> :NERDTreeToggle<CR>

          " Ctrl + f: Abre a busca rápida de arquivos (FZF)
          nnoremap <C-f> :Files<CR>

          " Tecla ESC: Limpa o brilho das buscas feitas anteriormente
          nnoremap <esc> :noh<return><esc>

          " Ctrl + t: Abre terminal embaixo
          nnoremap <C-t> :terminal<CR>
        '';
      };
    };
}
