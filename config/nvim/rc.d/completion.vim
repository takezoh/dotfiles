"---------------------------------------------------------------------------------
" Complete
"---------------------------------------------------------------------------------
" set wildmenu						" コマンド保管を強化
" set wildchar=<tab>			" コマンド保管を開始するキー
" set wildmode=list:full	" リスト表示、最長マッチ
" set history=1000				" コマンド・検索パターンの履歴数
" set complete+=k					" 保管に辞書ファイル追加
"
" " -- tabでオムニ補完
" function! InsertTabWrapper()
" 	if pumvisible()
" 		return "\<c-n>"
" 	endif
" 	let col = col('.') - 1
" 	if !col || getline('.')[col -1] !~ '\k\|<\|/'
" 		return "\<tab>"
" 	elseif exists('&omnifunc') && &omnifunc == ''
" 		return "\<c-n>"
" 	else
" 		return "\<c-x>\<c-o>"
" 	endif
" endfunction
" inoremap <tab> <c-r>=InsertTabWrapper()<cr>
"
" if !exists('g:neocomplete#force_omni_input_patterns')
" 	let g:neocomplete#force_omni_input_patterns = {}
" endif
" let g:neocomplete#force_omni_input_patterns.cs = '[^.]\.\%(\u\{2,}\)\?'
"
"
" " Enable omni completion.
" autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
" autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
" autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
" autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
" autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
"
"
" "------------------------------------
" " neocomplete
" "------------------------------------
" let g:neocomplete#enable_at_startup = 1
" let g:acp_enableAtStartup = 0
" let g:neocomplet#enable_smart_case = 1
"
"
" "-------------------------------------------
" " OmniSharp
" "-------------------------------------------
" "Set the type lookup function to use the preview window instead of the status line
" let g:OmniSharp_typeLookupInPreview = 1
"
" "Showmatch significantly slows down omnicomplete
" "when the first match contains parentheses.
" set noshowmatch
"
" "Super tab settings
" let g:SuperTabDefaultCompletionType = 'context'
" let g:SuperTabContextDefaultCompletionType = "<c-x><c-o>"
" let g:SuperTabDefaultCompletionTypeDiscovery = ["&omnifunc:<c-x><c-o>","&completefunc:<c-x><c-n>"]
" let g:SuperTabClosePreviewOnPopupClose = 1
"
" "don't autoselect first item in omnicomplete, show if only one item (for preview)
" set completeopt=longest,menuone,preview
"
" nnoremap <leader>g :OmniSharpGotoDefinition<cr>
" nnoremap <leader>t :OmniSharpTypeLookup<cr>
" nnoremap <leader>l :OmniSharpFindUsages<cr>
" " nnoremap <leader>syn :OmniSharpFindSyntaxErrors<cr>
" nnoremap <leader>act :OmniSharpGetCodeActions<cr>
" nnoremap <leader>imples :OmniSharpFindImplementations<cr>
" " nnoremap <leader>reload :OmniSharpReloadSolution<cr>
