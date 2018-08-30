let g:python_host_prog = '/usr/bin/python'  " shims 通すと遅いので直接パスを書く
let g:python3_host_prog = '/usr/local/bin/python3'  " shims 通すと遅いので直接パスを書く

" vundle.vim
source $XDG_CONFIG_HOME/nvim/rc.d/bundle.vim
" 基本設定
source $XDG_CONFIG_HOME/nvim/rc.d/basic.vim
" 表示設定
source $XDG_CONFIG_HOME/nvim/rc.d/style.vim
" エンコーディング
source $XDG_CONFIG_HOME/nvim/rc.d/encoding.vim
" 操作設定
source $XDG_CONFIG_HOME/nvim/rc.d/operations.vim
" コーディング設定
source $XDG_CONFIG_HOME/nvim/rc.d/coding.vim


" VSCode で開く
command Code call system('code --reuse-window --goto ' . expand("%.p") . ':' . line("."))

set sh="zsh -l"
tnoremap <slent> <esc> <C-\><C-n>

" let g:ycm_global_ycm_extra_conf = $XDG_CONFIG_HOME . '/nvim/ycm/extra_conf.py'
