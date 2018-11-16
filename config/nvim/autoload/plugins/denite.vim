noremap [denite]  <Nop>
map <C-u> [denite]

" ファイルリスト
nnoremap <silent> <C-p> :<C-u>Denite file_rec<CR>
" ヤンクリスト
nnoremap <silent> <C-y> :<C-u>Denite neo_yank<CR>

" word grep
nnoremap <silent> ,wg :<C-u>DeniteCursorWord -buffer-name=search grep<CR><C-R><C-W><CR>
" grep
nnoremap <silent> ,g :<C-u>Denite -buffer-name=search -mode=insert grep<CR>
" search
nnoremap <silent> ,s :<C-u>Denite -buffer-name=search -auto-resize line<CR>
" resume previous buffer
nnoremap <silent> ,ur :<C-u>Denite -buffer-name=search -resume -mode=insert<CR>
"nnoremap <silent> [denite]<C-r> :<C-u>Denite -buffer-name=search -resume -mode=insert<CR>
"nnoremap <silent> [denite]<C-n> :<C-u>Denite -buffer-name=search -resume -select=+1 -immediately -mode=insert<CR>
"nnoremap <silent> [denite]<C-p> :<C-u>Denite -buffer-name=search -resume -select=-1 -immediately -mode=insert<CR>


" gtags
noremap [gtags]  <Nop>
nmap ,t [gtags]
nnoremap [gtags]d :<C-u>DeniteCursorWord -buffer-name=search -mode=insert gtags_def<CR>
nnoremap [gtags]r :<C-u>DeniteCursorWord -buffer-name=search -mode=insert gtags_ref<CR>
nnoremap [gtags]c :<C-u>DeniteCursorWord -buffer-name=search -mode=insert gtags_context<CR>
"nnoremap [gtags]e :<C-u>Denite -buffer-name=search gtags_completion<cr>

" Outline
" nnoremap <silent> ,uo :<C-u>Unite -no-quit -vertical -winwidth=40 outline<CR>
nnoremap <silent> ,uo :<C-u>Denite unite:outline<CR>
