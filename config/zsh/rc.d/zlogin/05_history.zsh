# historical backward/forward search with linehead string binded to ^P/^N
#
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
# bindkey "\\ep" history-beginning-search-backward-end
# bindkey "\\en" history-beginning-search-forward-end
# bindkey "^R" history-incremental-search-backward
# bindkey "^S" history-incremental-search-forward

# reverse menu completion binded to Shift-Tab
#
bindkey "\e[Z" reverse-menu-complete


## Command history configuration
#
HISTFILE="$XDG_DATA_HOME/zsh/history"
HISTSIZE=10000000
SAVEHIST=10000000

setopt share_history        # 同一ホストでヒストリを共有
setopt extended_history     # 実行時間

setopt hist_reduce_blanks   # 余分なスペースを詰めて記録

setopt hist_ignore_dups     # 直前のコマンドの重複を削除する。
setopt hist_ignore_all_dups # 重複するコマンドが記録される時、古い方を削除する。
setopt hist_save_no_dups    # 重複するコマンドが保存される時、古い方を削除する。
setopt hist_expire_dups_first # 古い履歴を削除する必要がある場合、まず重複しているものから削除する。
setopt hist_find_no_dups    # 履歴検索で重複しているものを表示しない。

# setopt append_history       # 履歴を上書きしないで追加する。
setopt hist_no_store        # historyコマンドは除去する。


__hist_ignore_cmd=(j gr pd)

zshaddhistory() {
	# strip
	local line="$(echo ${1%%$'\n'} | sed -e 's/^ *//' | sed -e 's/ *$//')"
	local cmd="${line%% *}"

	for ignore_cmd in $__hist_ignore_cmd; do
		if [ "$cmd" = "$ignore_cmd" ]; then
			return 1
		fi
	done

	return 0
}
