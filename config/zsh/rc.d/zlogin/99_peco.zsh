# if use fzf
if type fzf >/dev/null 2>&1; then
	# alias peco="fzf -e --ansi --multi --no-sort --reverse"
	if [ "$OSTYPE" = "cygwin" ]; then
		alias peco="tac | fzf -e --multi --no-sort --reverse"
	else
		alias peco="fzf -e --multi --no-sort --reverse"
	fi
fi

# peco/fzf
if type peco >/dev/null 2>&1; then

	# ps with peco
	alias ps="ps aux | peco"

	# jump to recently visited directory
	if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
		autoload -Uz chpwd_recent_dirs cdr
		add-zsh-hook chpwd chpwd_recent_dirs
		# zstyle ':completion:*:*:cdr:*:*' menu selection
		# zstyle ':completion:*' recent-dirs-insert both
		zstyle ':completion:*' recent-dirs-insert always
		zstyle ':chpwd:*' recent-dirs-default true
		# zstyle ':chpwd:*' recent-dirs-pushd true
		zstyle ':chpwd:*' recent-dirs-max 1000
		zstyle ':chpwd:*' recent-dirs-file "${XDG_DATA_HOME}/zsh/chpwd-recent-dirs"
		_z__cd() {
			local selected_dir=`cdr -l | sed -e 's/^[0-9]* *//' | peco --prompt="* search directory >>"`
			if [ -n "$selected_dir" ]; then
				eval "\\cd ${selected_dir}"
			fi
		}
		alias j="_z__cd"
	fi

	if type ghq >/dev/null 2>&1; then
		# jump to git repository
		_jump_repo() {
			local selected_repo=`ghq list -p | peco --prompt="* search repository >>"`
			if [ -n "$selected_repo" ]; then
				\cd $selected_repo
			fi
		}
		alias gr="_jump_repo"
	fi

	# git branch selection
	function peco-git-branch-selection() {
		local selected_branch=$(git branch -a | peco --prompt "* search git branch >>" | sed -e "s/^[\* ] *//g" | sed -e "s/^remotes\///g")
		BUFFER="${BUFFER}${selected_branch}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N peco-git-branch-selection
	bindkey '^G^B' peco-git-branch-selection

	# git files selection
	function peco-git-file-selection() {
		local selected_file=$(git ls-files | peco --prompt "* search git indexing file >>")
		BUFFER="${BUFFER}${selected_file}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N peco-git-file-selection
	bindkey '^G^F' peco-git-file-selection

	# file * search selection
	function peco-file-selection() {
		local selected_file=$(find . -path "./.git" -prune -o -type f | awk '{ print substr($0, 3); }' | peco --prompt "* search file >>")
		BUFFER="${BUFFER}${selected_file}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N peco-file-selection
	bindkey '^F' peco-file-selection

	# ヒストリのインクリメンタルサーチ
	function peco-history-selection() {
		BUFFER=`history -rn 1 | peco --query "$LBUFFER" --prompt "* search history >>"`
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N peco-history-selection
	bindkey '^R' peco-history-selection
fi
