" =============================================================================
" 1. GERENCIADOR DE PLUGINS (vim-plug)
" =============================================================================
call plug#begin('~/.vim/plugged')

" Tema Catppuccin (Mocha) - Estética moderna e confortável
Plug 'catppuccin/vim', { 'as': 'catppuccin' }

" NERDTree - Explorador de arquivos em árvore na lateral
Plug 'preservim/nerdtree'

" Vim-Airline - Barra de status elegante no rodapé
Plug 'vim-airline/vim-airline'

" Temas para a barra Airline (para combinar com o Catppuccin)
Plug 'vim-airline/vim-airline-themes'

" FZF - Motor de busca ultra-rápido para arquivos e textos
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Auto-pairs - Fecha automaticamente parênteses, chaves e aspas
Plug 'jiangmiao/auto-pairs'

call plug#end()


" =============================================================================
" 2. CONFIGURAÇÕES VISUAIS E DE TEMA
" =============================================================================

" Ativa o realce de sintaxe (cores no código)
syntax on

" Habilita suporte a cores de 24 bits no terminal
set termguicolors

" Define o esquema de cores para o Catppuccin Mocha
colorscheme catppuccin_mocha

" Faz a barra Airline usar o tema do Catppuccin
let g:airline_theme = 'catppuccin_mocha'

" Exibe o número da linha atual
set number

" Exibe números relativos (ajuda em comandos como '5j' ou '10k')
set relativenumber

" Destaca a linha onde o cursor está parado
set cursorline

" Esconde o modo padrão (-- INSERT --) pois o Airline já mostra
set noshowmode

" Faz com que novos splits horizontais abram sempre na parte de baixo
set splitbelow

" Faz com que novos splits verticais abram sempre na direita
set splitright

" CONFIGURAÇÃO DO EXPLORADOR (NERDTree)
" Faz o explorador abrir no lado DIREITO da tela
let g:NERDTreeWinPos = "right"

" Mantém sempre 10 linhas visíveis acima/abaixo do cursor ao rolar
set scrolloff=10


" =============================================================================
" 3. COMPORTAMENTO E NAVEGAÇÃO
" =============================================================================

" Habilita o mouse para clicar, rolar e redimensionar janelas
set mouse=a

" Permite trocar de arquivos (buffers) sem precisar salvar o atual primeiro
set hidden

" Melhora o menu de sugestões na barra de comandos (ao usar TAB)
set wildmenu

" Exibe comandos incompletos no canto inferior da tela
set showcmd

" Integra o Copiar/Colar do Vim com o do seu Sistema Operacional
set clipboard=unnamedplus

" Mantém a indentação da linha anterior ao criar uma nova
set autoindent

" Tenta adivinhar a indentação correta baseada na linguagem (C, PHP, etc)
set smartindent

" Reduz o atraso de resposta do editor (bom para plugins)
set updatetime=300

" Quebra linhas longas visualmente para não sumirem da tela
set wrap
set linebreak


" =============================================================================
" 4. BUSCA (SEARCH)
" =============================================================================

" Realça todos os resultados encontrados na busca
set hlsearch

" Mostra o resultado enquanto você ainda está digitando a busca
set incsearch

" Ignora maiúsculas/minúsculas ao buscar
set ignorecase

" Se a busca tiver letra maiúscula, ele torna a busca exata (Smart Case)
set smartcase


" =============================================================================
" 5. ARQUIVOS E BACKUP (LIMPEZA)
" =============================================================================

" Desativa a criação de arquivos .swp (swap) que poluem as pastas
set noswapfile

" Desativa arquivos de backup automáticos
set nobackup
set nowritebackup


" =============================================================================
" 6. ATALHOS DE TECLADO (MAPPINGS)
" =============================================================================

" Ctrl + e: Abre ou fecha o explorador de arquivos (NERDTree)
nnoremap <C-e> :NERDTreeToggle<CR>

" Ctrl + f: Abre a busca rápida de arquivos (FZF)
nnoremap <C-f> :Files<CR>

" Tecla ESC: Limpa o brilho das buscas feitas anteriormente
nnoremap <esc> :noh<return><esc>

" Ctrl + t: Abre terminal embaixo
nnoremap <C-t> :terminal<CR>
