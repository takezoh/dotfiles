"---------------------------------------------
" インデント設定
"---------------------------------------------
set autoindent	" 自動インデント
" set paste		" ペースト時にautoindentを無効
set smartindent	" 改行後のインデント量を合わせる
" set cindent		" Cプログラムの自動インデント

" Default
set tabstop=2
set shiftwidth=2
set softtabstop=0
set noexpandtab

" Python
autocmd BufReadPre *.py setlocal expandtab tabstop=4 shiftwidth=4
" C#
autocmd BufReadPre *.cs setlocal expandtab tabstop=4 shiftwidth=4
" Web
autocmd BufReadPre *.html,*.js,*.css,*.sass,*.vue,*.jsx,*.php setlocal expandtab tabstop=2 shiftwidth=2


"---------------------------------------------
" ファイルタイプ
"---------------------------------------------
" Vue
autocmd FileType vue syntax sync fromstart
" autocmd BufRead,BufNewFile *.vue setlocal filetype=vue.html.javascript.css  " nerdcommenter が動かないので無効化
"usf, ush
autocmd BufRead,BufNewFile *.usf setfiletype hlsl
autocmd BufRead,BufNewFile *.ush setfiletype hlsl

"---------------------------------------------
" ファイル保存時コマンド
"---------------------------------------------
if expand("%:e") != "md"
	" シンタックスチェック
	" autocmd BufWritePre *.cs :OmniSharpFindSyntaxErrors

	" 行末の空白を除去
	autocmd BufWritePre * :%s/\s\+$//ge

	" C#: bomb を付与
	autocmd BufWritePre *.cs :set fenc=utf-8 bomb
endif

if has("unix") && match(system("uname"),'Darwin') != -1
	" UTF8保存時にMacのファイル拡張属性を付加
	autocmd BufWritePost * call SetUTF8Xattr(expand("<afile>"))
	function! SetUTF8Xattr(file)
		if &fileencoding == "utf-8" || ( &fileencoding == "" && &encoding == "utf-8")
			call system("xattr -w com.apple.TextEncoding 'utf-8;134217984' '" . a:file . "'")
		endif
	endfunction
endif
