"---------------------------------------------------------------------------------
" 基本設定
"---------------------------------------------------------------------------------
set nocompatible
let mapleader = ","							" キーマップリーダー
set scrolloff=5									" スクロール時の余白
set textwidth=0									" 自動折り返し
set nowrap											" 自動折り返し無効
set nobackup										" バックアップ無効
set autoread										" 書き換えられたら再読込
set noswapfile									" スワップファイル作らない
set hidden											" 編集中でも開ける
set backspace=indent,eol,start	" バックスペースで削除する文字
set formatoptions=lmoq					" テキスト整形オプション、マルチバイト系を追加
set vb t_vb=										" ビープ音無効
"set browsedir=buffer						" Exploreの初期ディレクトリ
"set whichwrap=b,s,h,l,<,>,[,]	" カーソルを行頭、行末で止まらないようにする
set showcmd											" コマンドをステータス行に表示
set showmode										" 現在のモードを表示
"set viminfo='50,<1000,s100,\"50	" viminfoファイルの設定
"set modelines=0								" モードライン無効

" EXモード無効化
nnoremap Q <Nop>
" ファイル閉じる系無効化
nnoremap ZZ <Nop>
nnoremap ZQ <Nop>

" クリップボード共有
if has('clipboard')
	set clipboard=unnamedplus
endif

set helpfile=$VIMRUNTIME/doc/help.txt

" ワイルドカードで表示するときに優先度を低くする拡張子
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc


"---------------------------------------------------------------------------------
" Search
"---------------------------------------------------------------------------------
set wrapscan		" 最後まで検索したら先頭へ戻る
set ignorecase	" 大文字小文字無視
set smartcase		" 検索文字列に大文字が含まれている場合は区別して検索
set incsearch		" インクリメンタルサーチ
set hlsearch		" 検索文字ハイライト

" 検索ハイライトの消去
nmap <Esc><Esc> :nohlsearch<Enter>

