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

          " O NERDTree usa Ctrl+J/K para pular entre pastas irmãs; passa para Alt+J/K
          " (Ctrl+J/K ficam para trocar de janela, ver os atalhos abaixo)
          let g:NERDTreeMapJumpNextSibling = '<M-j>'
          let g:NERDTreeMapJumpPrevSibling = '<M-k>'

          " Menu do NERDTree (tecla m) em português, com a dica de como criar pasta
          function! s:TraduzirMenuNERDTree() abort
            if !exists('g:NERDTreeMenuItem')
              return
            endif
            let l:textos = {
              \ 'a': '(a) criar arquivo ou pasta  (pasta: termine o nome com /)',
              \ 'm': '(m) mover ou renomear',
              \ 'd': '(d) apagar',
              \ 'c': '(c) copiar',
              \ 'p': '(p) copiar o caminho',
              \ 'l': '(l) ver detalhes (tamanho, permissões)',
              \ 'C': '(C) mudar as permissões',
              \ 'r': '(r) mostrar no gerenciador de arquivos',
              \ 'o': '(o) abrir com o programa padrão',
              \ 's': '(s) rodar um comando nesta pasta',
              \ '!': '(!) executar o arquivo',
              \ }
            for l:item in g:NERDTreeMenuItem.All()
              if has_key(l:textos, l:item.shortcut)
                let l:item.text = l:textos[l:item.shortcut]
              endif
            endfor
          endfunction
          autocmd VimEnter * call s:TraduzirMenuNERDTree()

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

          " Ctrl + t: Abre ou esconde o terminal embaixo (o mesmo terminal volta,
          " com o que estava rodando; funciona também de dentro do terminal)
          function! ToggleTerminal() abort
            if exists('g:terminal_buf') && bufexists(g:terminal_buf)
                  \ && term_getstatus(g:terminal_buf) =~# 'running'
              let l:win = bufwinnr(g:terminal_buf)
              if l:win > 0
                execute l:win . 'wincmd w'
                hide
              else
                execute 'botright sbuffer ' . g:terminal_buf
                resize 12
              endif
            else
              botright terminal ++rows=12
              let g:terminal_buf = bufnr('%')
            endif
          endfunction
          nnoremap <silent> <C-t> :call ToggleTerminal()<CR>
          tnoremap <silent> <C-t> <C-w>:call ToggleTerminal()<CR>

          " Ctrl + h/j/k/l: Troca de janela (esquerda/baixo/cima/direita),
          " igual no arquivo, na árvore e no terminal
          nnoremap <C-h> <C-w>h
          nnoremap <C-j> <C-w>j
          nnoremap <C-k> <C-w>k
          nnoremap <C-l> <C-w>l
          tnoremap <C-h> <C-w>h
          tnoremap <C-j> <C-w>j
          tnoremap <C-k> <C-w>k
          tnoremap <C-l> <C-w>l
        '';
      };
    };
}
