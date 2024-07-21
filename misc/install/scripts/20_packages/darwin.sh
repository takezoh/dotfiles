#/bin/bash
set -ex

brew_formulas=(
  lv
  tree
  wget
  curl

  zsh
  python
  git
  tig

  bat
  # pandoc

  # make
  cmake

  nkf
  source-highlight

  awscli
  peco
  fzf
  # nvim
  python3
  ripgrep
  # global
  # mono

  apktool

  # lua
  # luaenv
  # lua-build
  # python
  pyenv
  pyenv-virtualenv
  # golang
  goenv
  # ruby
  rbenv
  ruby-build
  rbenv-gemset
  # web
  yarn
  nodenv
  node-build
  # java
  jenv

  # jadx
  # dex2jar
)

if ! type brew >/dev/null 2>&1; then
	xcode-select --install >/dev/null || true
	# if ! xcode-select --install >/dev/null 2>&1; then
	#  	return 1
	# fi
	# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew update
brew upgrade
brew install ${brew_formulas[@]}
