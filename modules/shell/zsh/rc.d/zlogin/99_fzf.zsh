if type fzf >/dev/null 2>&1; then
	export FZF_DEFAULT_OPTS="--reverse --no-sort --height=60% --border --inline-info"
	if type rg >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git/'"
	fi
	# file search options (preview + multi) — applied only to file-oriented fzf calls
	_fzf_file_opts="--multi"
	if type bat >/dev/null 2>&1; then
		_fzf_file_opts="${_fzf_file_opts} --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || echo {}'"
	fi

	# ps with fzf
	alias ps="ps aux | fzf --preview=''"

	# jump to directory (zoxide)
	if type zoxide >/dev/null 2>&1; then
		eval "$(zoxide init zsh)"
		alias j="zi"
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
		local selected_file=$(eval "${FZF_DEFAULT_COMMAND:-find . -type f}" | eval "fzf ${_fzf_file_opts} --prompt '* search file >>'")
		BUFFER="${BUFFER}${selected_file}"
		CURSOR=$#BUFFER
		zle reset-prompt
	}
	zle -N fzf-file-selection
	bindkey '^F' fzf-file-selection

fi
