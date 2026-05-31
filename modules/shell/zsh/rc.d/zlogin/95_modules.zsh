# auto-fu
# source ~/.zsh/modules/auto-fu.zsh/auto-fu.zsh
# zle-line-init() { auto-fu-init; }
# zle -N zle-line-init
# zstyle ':auto-fu:var' postdisplay $''

# zsh-autosuggestions (must be before zsh-syntax-highlighting)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_USE_ASYNC=1
source $DOTFILES_EXTERNAL_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
source $DOTFILES_EXTERNAL_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
