" only vim
syntax on
set encoding=utf-8
set number
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set list listchars=tab:\|\ 
" ディレクトリをあらかじめ作っておく必要がある
set undodir=~/.vim_undo
set undofile
set noswapfile
set backspace=2
set ignorecase " 検索のとき大文字小文字に関係なくヒット
set smartcase " 検索する文字に一文字でも大文字があれば、大文字小文字を厳密に検索

set confirm
set autoread
set mouse=a
set incsearch
set foldmethod=indent
set foldlevel=99
set clipboard+=unnamed
let loaded_matchparen = 1
set fileencodings=utf-8,sjis,iso-2022-jp,euc-jp
set termguicolors
set exrc " カレントディレクトリの .exrc / .nvim.lua を読み込む
set secure " 危険なコマンドは無効化

" autocmd が二重に登録されないようにする
" デフォルトのグループを kekemoto に設定"
augroup kekemoto
" kekemoto に登録されている自動コマンドを削除
autocmd!

" 挿入モードからノーマルモードに戻る時に自動でペーストモードを解除
autocmd InsertLeave * set nopaste

" 挿入モードで直近の検索ハイライトを消す
autocmd! InsertEnter * call feedkeys("\<Cmd>noh\<cr>" , 'n')

" WSL で、ヤンクでクリップボードにコピー
if system('uname -a | grep WSL') != ''
  autocmd TextYankPost * :call system('clip.exe', @")
endif

" 外部コマンドがエラーの時だけ、画面分割して出力するヘルパー
function! SafeSystem(command, error_message) abort
  let s:result = system(a:command)
  if v:shell_error != 0
    split +enew
    set paste
    execute ":normal i" . s:result
    " winc w
    throw a:error_message
  endif
endfunction

" 自動フォーマット
" call system("type npx")
" if v:shell_error == 0
"   function! PrettierFmt() abort
"     call SafeSystem("npx prettier --write " . expand("%"), 'prettier')
"     e
"   endfunction
" 
"   autocmd BufWritePost *.js,*.jsx,*.mjs,*.ts,*.tsx,*.css,*.less,*.scss,*.json,*.graphql,*.gql,*.markdown,*.md,*.mdown,*.mkd,*.mkdn,*.mdx,*.vue,*.svelte,*.yml,*.yaml,*.html,*.php,*.rb,*.ruby,*.xml call PrettierFmt()
" "endif

" 開いているファイルのパスをクリップボードに登録
" Filepath Copy
function! FC() abort
  let @+ = expand("%")
endfunction

" キーマップ
let mapleader = "\<Space>"

noremap <Leader>p "0p 
nnoremap <Leader>w :w<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>x :x<CR>
nnoremap <Leader>t :tabnew<CR>
nnoremap <Leader>e :Ex<CR>
nnoremap <Leader>b :CtrlPBuffer<CR>
if has('nvim')
  nnoremap <Leader>s :source ~/.config/nvim/init.vim<CR>
else
  nnoremap <Leader>s :source ~/.vimrc<CR>
endif
if has('nvim')
  nnoremap gd :lua vim.lsp.buf.definition()<CR>
  nnoremap gD <Cmd>tab split<CR><Cmd>lua vim.lsp.buf.definition()<CR>
  nnoremap <Leader>lf :lua vim.lsp.buf.format()<CR>
  nnoremap <Leader>ls :lua vim.lsp.buf.document_symbol()<CR>
  nnoremap <Leader>lr :lua vim.lsp.buf.references()<CR>
  nnoremap <Leader>ln :lua vim.lsp.buf.rename()<CR>
  nnoremap <Leader>lh :lua vim.lsp.buf.hover()<CR>
  nnoremap <Leader>la :lua vim.lsp.buf.code_action()<CR>
  nnoremap <Leader>dl :lua vim.diagnostic.setqflist()<CR>
  nnoremap <Leader>dd :lua vim.diagnostic.open_float()<CR>
  nnoremap <Leader>dn :lua vim.diagnostic.goto_next()<CR>
  nnoremap <Leader>dp :lua vim.diagnostic.goto_prev()<CR>
endif
inoremap <C-a> <End><Enter>
inoremap <C-o> <C-x><C-o>
inoremap { {}<LEFT>
inoremap [ []<LEFT>
inoremap ( ()<LEFT>
inoremap " ""<LEFT>
inoremap ' ''<LEFT>
inoremap ` ``<LEFT>
if !has('nvim')
  autocmd BufRead *.html inoremap <buffer> < <><LEFT>
endif

tnoremap <C-w> <C-\><C-n>

" サブモードで視覚的に移動する
" @see https://zenn.dev/mattn/articles/83c2d4c7645faa
nmap gj gj<SID>g
nmap gk gk<SID>g
nnoremap <script> <SID>gj gj<SID>g
nnoremap <script> <SID>gk gk<SID>g
nmap <SID>g <Nop>

" TypeScript
"
" install LSP
"   npm install -g typescript typescript-language-server
if executable('typescript-language-server')
  lua <<EOF
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json" },
    callback = function()
      vim.lsp.start({
        name = "typescript-language-server",
        cmd = { "typescript-language-server", "--stdio" },
        root_dir = vim.fs.root(0, { "tsconfig.json", "package.json", ".git" }),
        filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json" },
        init_options = {
          hostInfo = "neovim",
        },
      })
    end,
  })
EOF
endif

" PHP
"
" install LSP
"   cd ~/.local/bin
"   curl -L https://github.com/phpactor/phpactor/releases/latest/download/phpactor.phar -o phpactor
"   chmod +x phpactor
"   curl -L https://github.com/phpstan/phpstan/releases/latest/download/phpstan.phar -o phpstan
"   chmod +x phpstan
if executable('phpactor')
  lua <<EOF
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "php",
      callback = function()
        vim.lsp.start({
          name = "phpactor",
          cmd = { "phpactor", "language-server" },
          root_dir = vim.fs.root(0, { "composer.json", ".git" }),
          filetypes = { "php" },
          init_options = {
            ["language_server_phpstan.enabled"] = false,
            ["language_server_psalm.enabled"] = false,
          },
        })
        vim.diagnostic.disable(0)
      end,
    })
EOF
endif

" Go
autocmd FileType go setlocal noexpandtab
autocmd FileType go setlocal tabstop=4
autocmd FileType go setlocal shiftwidth=4

" Zig
"
" install LSP
"   asdf plugin add zls
"   asdf install zls 0.14.0
"   asdf global zls 0.14.0
if executable('zls')
  lua <<EOF
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "zig",
      callback = function()
        vim.lsp.start({
          name = "zls",
          cmd = { "zls" },
          root_dir = vim.fs.root(0, { "build.zig", ".git" }),
          filetypes = { "zig" },
        })
      end,
    })
EOF
endif

filetype plugin indent on
call plug#begin()
" 補完
Plug 'echasnovski/mini.completion'
" grep
Plug 'jremmen/vim-ripgrep'
" syntax highlight for twig
Plug 'sheerun/vim-polyglot'
" ファイルファインダー
Plug 'ctrlpvim/ctrlp.vim'
" HTMLタグを自動で閉じる
Plug 'alvan/vim-closetag'
" カッコの編集
Plug 'tpope/vim-surround'
" git 表示
Plug 'lewis6991/gitsigns.nvim'
" カラーテーマ
Plug 'navarasu/onedark.nvim'
call plug#end()

lua <<EOF
  -- Plug 'echasnovski/mini.completion'
  require('mini.completion').setup()
  -- Plug 'lewis6991/gitsigns.nvim'
  require('gitsigns').setup {
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', '<Leader>j', function()
        if vim.wo.diff then
          vim.cmd.normal({']c', bang = true})
        else
          gitsigns.nav_hunk('next')
        end
      end)

      map('n', '<Leader>k', function()
        if vim.wo.diff then
          vim.cmd.normal({'[c', bang = true})
        else
          gitsigns.nav_hunk('prev')
        end
      end)
    end
  }
EOF

" Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

" Plug 'navarasu/onedark.nvim'
colorscheme onedark

" neovim のみの設定
if has('nvim')
  autocmd BufWritePre *.go,*.js,*.ts lua vim.lsp.buf.format({ async = false })
endif
