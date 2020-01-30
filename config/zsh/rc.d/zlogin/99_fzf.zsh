if type fzf >/dev/null 2>&1; then
	if [ "$OSTYPE" = "cygwin" ]; then
		alias fzf="tac | fzf -e --multi --no-sort --reverse"
	else
		alias fzf="fzf -e --multi --no-sort --reverse"
	fi

	# ps with fzf
	alias ps="ps aux | fzf"

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
			local selected_dir=`cdr -l | sed -e 's/^[0-9]* *//' | fzf --prompt="* search directory >>"`
			if [ -n "$selected_dir" ]; then
				eval "\\cd ${selected_dir}"
			fi
		}
		alias j="_z__cd"
	fi

	if type ghq >/dev/null 2>&1; then
		# jump to git repository
		_jump_repo() {
			local selected_repo=`ghq list -p | fzf --prompt="* search repository >>"`
			if [ -n "$selected_repo" ]; then
				\cd $selected_repo
			fi
		}
		alias gr="_jump_repo"
	fi

	# git branch selection
	function fzf-git-branch-selection() {
		local selected_branch=$(git branch -a | fzf --prompt "* search git branch >>" | sed -e "s/^[\* ] *//g" | sed -e "s/^remotes\///g")
		BUFFER="${BUFFER}${selected_branch}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N fzf-git-branch-selection
	bindkey '^G^B' fzf-git-branch-selection

	# git files selection
	function fzf-git-file-selection() {
		local selected_file=$(git ls-files | fzf --prompt "* search git indexing file >>")
		BUFFER="${BUFFER}${selected_file}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N fzf-git-file-selection
	bindkey '^G^F' fzf-git-file-selection

	# file * search selection
	function fzf-file-selection() {
		# local selected_file=$(find . -path "./.git" -prune -o -type f | awk '{ print substr($0, 3); }' | fzf --prompt "* search file >>"
		local selected_file=$(rg --files . | awk '{ print substr($0, 3); }' | fzf --prompt "* search file >>" \
				--bind 'ctrl-l:execute-silent(launch-source {} & >/dev/null 2>&1)' \
				)
		BUFFER="${BUFFER}${selected_file}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N fzf-file-selection
	bindkey '^F' fzf-file-selection

	# ヒストリのインクリメンタルサーチ
	function fzf-history-selection() {
		BUFFER=`history -rn 1 | fzf --query "$LBUFFER" --prompt "* search history >>"`
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N fzf-history-selection
	bindkey '^R' fzf-history-selection
fi
