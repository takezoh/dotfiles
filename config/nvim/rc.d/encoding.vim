"---------------------------------------------------------------------------------
" Encoding
"---------------------------------------------------------------------------------
set ffs=unix,dos,mac  " 改行文字
set encoding=utf-8    " デフォルトエンコーディング

" 日本語を含まない場合は fileencoding に encoding を使うようにする
if has('autocmd')
	function! AU_ReCheck_FENC()
		if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
			let &fileencoding=&encoding
		endif
	endfunction
	autocmd BufReadPost * call AU_ReCheck_FENC()
endif

" 改行コードの自動認識
set fileformats=unix,dos,mac
" □とか○の文字があってもカーソル位置がずれないようにする
if exists('&ambiwidth')
	set ambiwidth=double
endif

" 指定文字コードで強制的にファイルを開く
command! Cp932 edit ++enc=cp932
command! Sjis edit ++enc=shift_jis
command! Eucjp edit ++enc=euc-jp
command! Jis edit ++enc=iso-2022-jp
command! Utf8 edit ++enc=utf-8
