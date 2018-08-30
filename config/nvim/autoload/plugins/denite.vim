" ファイルリスト
nnoremap <silent> <C-p> :<C-u>Denite file_rec<CR>

" カーソル以下の単語をgrep
nnoremap <silent> ,wg :<C-u>DeniteCursorWord grep -buffer-name=search line<CR><C-R><C-W><CR>
" 普通にgrep
nnoremap <silent> ,g :<C-u>Denite -buffer-name=search -mode=insert grep<CR>

" search
nnoremap <silent> ,s :<C-u>Denite -buffer-name=search -auto-resize line<CR>

" resume previous buffer
nnoremap <silent> ,ur :<C-u>Denite -buffer-name=search -resume -mode=insert<CR>


" gtags
noremap [gtags]  <Nop>
nmap ,t [gtags]
nnoremap [gtags]d :<C-u>DeniteCursorWord -buffer-name=gtags_def -mode=insert gtags_def<CR>
nnoremap [gtags]r :<C-u>DeniteCursorWord -buffer-name=gtags_ref -mode=insert gtags_ref<CR>
nnoremap [gtags]c :<C-u>DeniteCursorWord -buffer-name=gtags_context -mode=insert gtags_context<CR>
nnoremap [gtags]e :<C-u>Denite -buffer-name=gtags_completion gtags_completion<cr>

" Outline
" nnoremap <silent> ,uo :<C-u>Unite -no-quit -vertical -winwidth=40 outline<CR>
nnoremap <silent> ,uo :<C-u>Denite unite:outline<CR>
