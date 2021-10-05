"---------------------------------------------------------------------------------
" Move
"---------------------------------------------------------------------------------
" insert mode での移動
imap  <C-e> <END>
imap  <C-a> <HOME>
" インサートモードでもhjklで移動（Ctrl押すけどね）
imap <C-j> <Down>
imap <C-k> <Up>
imap <C-h> <Left>
imap <C-l> <Right>

imap OA <Up>
imap OB <Down>
imap OC <Right>
imap OD <Left>

" 前回終了したカーソル行に移動
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

" 最後に編集された位置に移動
nnoremap gb '[
nnoremap gp ']

" 対応する括弧に移動
nnoremap [ %
nnoremap ] %

" 最後に変更されたテキストを選択する
"nnoremap gc  `[v`]
"vnoremap gc <C-u>normal gc<Enter>
"onoremap gc <C-u>normal gc<Enter>

" カーソル位置の単語をyankする
nnoremap vy vawy

" 矩形選択で自由に移動する
set virtualedit+=block

" CTRL-hjklでウィンドウ移動
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-k>j
nnoremap <C-l> <C-l>j
nnoremap <C-h> <C-h>j


"---------------------------------------------------------------------------------
" Edit
"---------------------------------------------------------------------------------
" ノーマルモードで<C-^>無効化
" nnoremap <silent> <C-^> <Nop>
"IME状態に応じたカーソル色を設定
if has('multi_byte_ime')
  highlight Cursor guifg=#000d18 guibg=#8faf9f gui=bold
  highlight CursorIM guifg=NONE guibg=#ecbcbc
endif

" augroup InsModeAu
    " autocmd!
    " autocmd InsertEnter,CmdwinEnter * set noimdisable
    " autocmd InsertLeave,CmdwinLeave * set imdisable
" augroup END

" insertモードを抜けるとIMEオフ
set noimdisable
set iminsert=0 imsearch=0
set noimcmdline
inoremap <silent> <ESC> <ESC>:set iminsert=0<CR>


" yeでそのカーソル位置にある単語をレジスタに追加
nmap ye ;let @"=expand("<cword>")<CR>
" Visualモードでのpで選択範囲をレジスタの内容に置き換える
vnoremap p <Esc>;let current_reg = @"<CR>gvdi<C-R>=current_reg<CR><Esc>

" コンマの後に自動的にスペースを挿入
" inoremap , ,<Space>

" Insert mode中で単語単位/行単位の削除をアンドゥ可能にする
inoremap <C-u>  <C-g>u<C-u>
inoremap <C-w>  <C-g>u<C-w>
