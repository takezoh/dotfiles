## Completion configuration
#
fpath=($ZDOTDIR/completions $fpath)
autoload -Uz compinit
if [[ -n $ZDOTDIR/.zcompdump(#qN.mh+24) ]]; then
	compinit
else
	compinit -C
fi
{ zcompile $ZDOTDIR/.zcompdump } &!


zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'
zstyle ':completion:*' menu select=1
# zstyle ':completion:*' menu select=2

zstyle ':completion:*' format '%B%d%b'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' keep-prefix

# zstyle ':completion:*' completer _oldlist _complete _match _history _ignored _approximate _prefix
zstyle ':completion:*' completer _oldlist _complete _match _ignored _approximate _prefix
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' verbose yes
zstyle ':completion:sudo:*' environ PATH="$SUDO_PATH:$PATH"

## カーソル位置で補完する。
setopt complete_in_word
## globを展開しないで候補の一覧から補完する。
setopt glob_complete
## 補完時にヒストリを自動的に展開する。
setopt hist_expand
## 補完候補がないときなどにビープ音を鳴らさない。
setopt no_beep
## 辞書順ではなく数字順に並べる。
setopt numeric_glob_sort


# fzf-tab (must be after compinit, before autosuggestions/syntax-highlighting)
if [ -f $DOTFILES_EXTERNAL_DIR/fzf-tab/fzf-tab.plugin.zsh ]; then
	source $DOTFILES_EXTERNAL_DIR/fzf-tab/fzf-tab.plugin.zsh
	zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
	zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || ls -1 --color=always $realpath 2>/dev/null || echo $word'
fi
