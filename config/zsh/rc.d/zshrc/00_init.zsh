## Environment variable configuration
#
# LANG
#
export LANG=ja_JP.UTF-8
export LC_TIME=C
case ${UID} in
0)
    # LANG=C
		LC_All=C
    ;;
esac

# stty ^S 無効化
if type stty >/dev/null 2>&1; then
	stty stop "undef"
fi


if [ -d /home/linuxbrew/.linuxbrew ]; then
	# if [ ! -f $HOME/.cache/linuxbrew/shellenv ]; then
	# 	mkdir -p $HOME/.cache/linuxbrew
	# 	/home/linuxbrew/.linuxbrew/bin/brew shellenv > $HOME/.cache/linuxbrew/shellenv
	# fi
	# source $HOME/.cache/linuxbrew/shellenv
	export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
	export HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
	export HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
fi

path=(
	# user
	$HOME/.local/bin(N-/)
	$HOME/.local/scripts(N-/)
	$path
)

# auto change directory
#
setopt auto_cd

# auto directory pushd that you can get dirs list by cd -[tab]
#
setopt auto_pushd

# command correct edition before each completion attempt
#
setopt correct

# compacked complete list display
#
setopt list_packed

# no remove postfix slash of command line
#
setopt noautoremoveslash

# no beep sound when complete list displayed
#
setopt nolistbeep

# setopt complete_aliases
#
setopt complete_aliases


## Keybind configuration
#
# emacs like keybind (e.x. Ctrl-a gets to line head and Ctrl-e gets
#   to end) and something additions
#
bindkey -v
# bindkey "^[[1~" beginning-of-line # Home gets to line head
# bindkey "^[[4~" end-of-line # End gets to line end
# bindkey "^[[3~" delete-char # Del


## zsh editor
#
autoload zed

## zargs
#
autoload zargs

## Prediction configuration
#
# autoload predict-on
# predict-off


## --prefix=~/localというように「=」の後でも
# 「~」や「=コマンド」などのファイル名展開を行う。
setopt magic_equal_subst

## 拡張globを有効にする。
# glob中で「(#...)」という書式で指定する。
setopt extended_glob
# globでパスを生成したときに、パスがディレクトリだったら最後に「/」をつける。
setopt mark_dirs

## jobsでプロセスIDも出力する。
setopt long_list_jobs

## 実行したプロセスの消費時間が3秒以上かかったら
## 自動的に消費時間の統計情報を表示する。
REPORTTIME=3

watch="all" # 全てのユーザのログイン・ログアウトを監視する。
# log # ログイン時にはすぐに表示する。

# setopt ignore_eof		# ^Dでログアウトしないようにする。

setopt no_hup					# ログアウト時にバックグラウンドジョブをハングアップしない
# setopt no_checkjobs		# ログアウト時にバックグラウンドジョブを確認しない
setopt notify					# バックグラウンドジョブが終了したらプロンプトを待たずに知らせる
unsetopt bg_nice
