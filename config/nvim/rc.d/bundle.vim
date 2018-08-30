"---------------------------------------------------------------------------------
" Plugins
"---------------------------------------------------------------------------------

if &compatible
  set nocompatible
endif

let s:bundle_dir = $XDG_CACHE_HOME . '/dein'
if &runtimepath !~# '/dein.vim'
	let s:dein_path = s:bundle_dir . '/repos/github.com/Shougo/dein.vim'
	if !isdirectory(s:dein_path)
		call system('mkdir -p ' . s:bundle_dir . ' && git clone https://github.com/Shougo/dein.vim ' . s:dein_path)
	endif
	execute 'set runtimepath+=' . s:dein_path
endif

if dein#load_state(s:bundle_dir)
	call dein#begin(s:bundle_dir)

	let s:bundle_conf_dir = $XDG_CONFIG_HOME . '/nvim/bundle'
	call dein#load_toml(s:bundle_conf_dir . '/style.toml', {'lazy': 0})

	call dein#load_toml(s:bundle_conf_dir . '/dein.toml', {'lazy': 0})
	call dein#load_toml(s:bundle_conf_dir . '/dein_lazy.toml', {'lazy': 1})

	call dein#load_toml(s:bundle_conf_dir . '/coding.toml', {'lazy': 0})
	call dein#load_toml(s:bundle_conf_dir . '/coding_lazy.toml', {'lazy': 1})

	call dein#end()
	call dein#save_state()
endif

filetype plugin indent on
syntax enable

if dein#check_install()
  call dein#install()
endif

if executable('rg')
	" using .ignore
	call denite#custom#var('file_rec', 'command', ['rg', '--files'])
	call denite#custom#var('grep', 'command', ['rg'])
	call denite#custom#var('grep', 'recursive_opts', [])
	call denite#custom#var('grep', 'default_opts', ['--vimgrep', '--no-heading'])
endif

call denite#custom#source('file_rec', 'matchers', ['matcher_fuzzy'])

" unite-outline の自動更新
let g:unite_source_outline_filetype_options = {
			\ '*': {
			\   'auto_update': 1,
			\   'auto_update_event': 'write',
			\ },
			\ 'cpp': {
			\   'ignore_types': ['enum', 'typedef', 'macro'],
			\ },
			\ 'javascript': {
			\   'ignore_types': ['comment'],
			\ },
			\ 'markdown': {
			\   'auto_update_event': 'hold',
			\ },
			\}


"------------------------------------
" VimShell
"------------------------------------
" if has('unix')
	" if system('uname') == "Darwin\n"
		" let g:vimproc_dll_path = $HOME . '/.vim/bundle/vimproc/autoload/proc_mac.so'
	" else
		" let g:vimproc_dll_path = $HOME . '/.vim/bundle/vimproc/autoload/proc_gcc.so'
	" endif
" endif


"------------------------------------
" unite.vim
"------------------------------------
" The prefix key.
" nnoremap    [unite]   <Nop>
" nmap    f [unite]

" nnoremap [unite]u  :<C-u>Unite<Space>
" nnoremap <silent> [unite]a  :<C-u>UniteWithCurrentDir -buffer-name=files buffer file_mru bookmark file<CR>
" nnoremap <silent> [unite]f  :<C-u>Unite -buffer-name=files file<CR>
" nnoremap <silent> [unite]b  :<C-u>Unite buffer<CR>
" nnoremap <silent> [unite]m  :<C-u>Unite file_mru<CR>

" " nnoremap <silent> [unite]b  :<C-u>UniteWithBufferDir -buffer-name=files buffer file_mru bookmark file<CR>

" autocmd FileType unite call s:unite_my_settings()
" function! s:unite_my_settings()"{{{
  " " Overwrite settings.
  " imap <buffer> jj      <Plug>(unite_insert_leave)
  " nnoremap <silent><buffer> <C-k> :<C-u>call unite#mappings#do_action('preview')<CR>
  " imap <buffer> <C-w>     <Plug>(unite_delete_backward_path)
  " " Start insert.
  " let g:unite_enable_start_insert = 1
" endfunction"}}}

" let g:unite_source_file_mru_limit = 200
