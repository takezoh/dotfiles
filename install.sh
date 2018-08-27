#!/bin/bash
set -ex

packages=(
	lv tree
	wget curl

	zsh python
	git tig

	# make
	cmake

	nkf
	source-highlight
)

add_packages_darwin() {
	packages+=(
		# htop
		# ant
		awscli
		peco
		nvim python3
		ripgrep
		ctags global
		mono

		direnv

		# lua
		# luaenv lua-build
		# python
		pyenv pyenv-virtualenv
		# golang
		goenv
		# ruby
		rbenv ruby-build rbenv-gemset
		# web
		yarn nodenv node-build
		# java
		jenv
	)
}

add_packages_linux() {
	if ! `dpkg -s "ripgrep" > /dev/null 2>&1`; then (
		cd /tmp
		curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.9.0/ripgrep_0.9.0_amd64.deb
		sudo dpkg -i ripgrep_0.9.0_amd64.deb
	) fi

	packages+=(
		ripgrep
		peco
		awscli
		neovim python3 python3-pip
		# ctags
		global
		# mono

		# direnv
		zip

		lua5.1

		# python
		# pyenv pyenv-virtualenv
		# golang
		# goenv
		# ruby
		# rbenv ruby-build rbenv-gemset
		# web
		# yarn nodenv node-build
		# java
		# jenv

		build-essential
		zlib1g-dev
		libssl-dev
		# libmysqlclient-dev
		# mysql-client
		# mysql-server
		# redis-server

		# terminal
		gnome-terminal dbus-x11 uim uim-xim uim-anthy
		language-pack-ja fonts-ipafont

		# X11
		# x11-utils x11-xserver-utils # libxslt1-dev
		# lxde lxsession-logout
		# fontconfig
	)
}

add_packages_cygwin() {
	packages+=(
		vim lua
	)
}

install() {
	cd $HOME
	clean-symbolic-link .

	# コピー元が $HOME 直下でなければ、シンボリックリンクを張る
	if [ ! "$(cd `dirname $root_dir` && pwd -P)" = "$(cd $HOME && pwd -P)" ]; then
		ln -snf $root_dir $dotfiles_dir
	fi

	# XDG config
	(
		mkdir -p $XDG_CONFIG_HOME
		cd $XDG_CONFIG_HOME
		clean-symbolic-link .
		for dname in $(cd $dotfiles_dir/config && command ls); do
			ln -snf $dotfiles_dir/config/${dname} .
		done
	)

	# .local
	(
		mkdir -p $HOME/.local
		cd $HOME/.local
		clean-symbolic-link .

		ln -snf $dotfiles_dir/scripts .
		[ -d $dotfiles_dir/.local/config ] && ln -snf $dotfiles_dir/.local/config .
	)

	# non-xdg dotfiles
	for conf in $(cd $XDG_CONFIG_HOME/non-xdg && command ls); do
		ln -snf $XDG_CONFIG_HOME/non-xdg/$conf .${conf}
	done

	# .zshenv
	ln -snf $XDG_CONFIG_HOME/zsh/.zshenv .
	mkdir -p .local/share/zsh

	# .vimrc
	ln -snf $XDG_CONFIG_HOME/nvim/init.vim .vimrc

	# ssh config
	(mkdir -p .ssh && chmod 700 .ssh && cd .ssh && ln -snf $XDG_CONFIG_HOME/ssh/config . && clean-symbolic-link .)
}

install_darwin() {
	rm -rf $HOME/Library/Application\ Support/Code/User
	mkdir -p $HOME/Library/Application\ Support/Code
	(cd $HOME/Library/Application\ Support/Code && ln -snf ~/.config/vscode User)
}

post_install_darwin() {
	# show dotfiles
	defaults write com.apple.finder AppleShowAllFiles TRUE
	defaults write com.apple.desktopservices DSDontWriteNetworkStores TRUE
	killall Finder

	#neovim
	pip3 install --upgrade pip
	pip3 install --upgrade neovim
	# vim -c "UpdateRemotePlugins" -c "quit\!"
}

install_wsl() {
	return 0
}

post_install_wsl() {
	if [ ! `basename $SHELL` = "zsh" ]; then
		chsh -s `which zsh`
	fi

	# X11
	# lxpanel --profile LXDE
	# sudo ln -snf /mnt/c/Windows/Fonts /usr/share/fonts/windows
	# sudo fc-cache -fv

	# python3
	LC_ALL="en_US.UTF-8" LC_CTYPE="en_US.UTF-8" sudo pip3 install --upgrade pip
	[ ! -x /usr/local/bin/python3 ] && sudo ln -snf /usr/bin/python3 /usr/local/bin/python3

	#neovim
	sudo pip3 install --upgrade neovim
	#vim -c "UpdateRemotePlugins" -c "quit\!"

	sudo mkdir -p /usr/local/opt
	sudo chown `whoami` /usr/local/opt

	(
		cd /usr/local/opt

		[ ! -d pyenv ] && (
			# pyenv
			sudo apt install libffi-dev
			git clone https://github.com/yyuu/pyenv.git
			git clone https://github.com/pyenv/pyenv-virtualenv.git
			(
				cd /usr/local/bin
				sudo ln -snf ../opt/pyenv/bin/pyenv .
				sudo ln -snf ../opt/pyenv-virtualenv/bin/pyenv-virtualenv .
			)
		)
		(cd pyenv && git pull -f origin master)
		(cd pyenv-virtualenv && git pull -f origin master)
	)
	(
		cd /usr/local/bin

		# fzf
		# [ ! -x fzf ] && sudo ln -snf $dotfiles_dir/misc/platform/linux/fzf-0.16.2-linux_amd64 fzf
	)
}

install_cygwin() {
	return 0
}

post_install_cygwin() {
	mkdir -p /usr/local/opt
	(
		cd /usr/local/opt

		(
			# apt-cyg
			mkdir -p apt-cyg
			cd apt-cyg
			curl -LO https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg
			chmod +x apt-cyg
			(cd /usr/local/bin && ln -snf ../opt/apt-cyg/apt-cyg apt)
		)
	)
	(
		cd /usr/local/bin

		# fzf
		[ ! -x fzf ] && ln -snf $dotfiles_dir/misc/platform/cygwin/fzf-0.8.9-x64 fzf
		# ripgrep
		[ ! -x rg ] && ln -snf $dotfiles_dir/misc/platform/ripgrep-0.7.1-x86_64-pc-windows-gnu.exe rg
		# peco
		[ ! -x peco ] && ln -snf $dotfiles_dir/misc/platform/windows/peco_0.5.2_windows_amd64.exe peco
	)
}

install_windows() {
	local cpath=wslpath
	local sysdir=/mnt/c/Windows/System32
	if [ "$OSTYPE" = "cygwin" ]; then
		cpath=cygpath
	fi
	if [ -d /cygdrive/c/Windows ]; then
		sysdir=/cygdrive/c/Windows/System32
	fi
	$sysdir/cmd.exe /c del "%USERPROFILE%\\.vsvimrc"
	$sysdir/cmd.exe /c mklink "%USERPROFILE%\\.vsvimrc" `$cpath -aw $dotfiles_dir/config/non-xdg/.vsvimrc`
	$sysdir/cmd.exe /c rmdir /s /q "%APPDATA%\\Code\\User"
	$sysdir/cmd.exe /c mklink /D "%APPDATA%\\Code\\User" `$cpath -aw $dotfiles_dir/config/vscode`

	cat <<EOF > $HOME/.local/platform-generated.gitconfig
[core]
	filemode = false
EOF
}

post_install_windows() {
	(
		cd /usr/local/opt
		if [ ! -d win32yank ]; then
			(
				cd /tmp
				curl -LO https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip
			)
			(
				mkdir win32yank
				cd win32yank
				cp /tmp/win32yank-x64.zip .
				unzip win32yank-x64.zip
				rm win32yank-x64.zip
				chmod +x win32yank.exe
			)
			(
				cd /usr/local/bin
				sudo ln -snf ../opt/win32yank/win32yank.exe win32yank
			)
		fi
	)
}

root_dir=$(cd `dirname $0` && pwd -P)
dotfiles_dir=`basename $root_dir`
# シンボリックリンク名のプレフィックスに "." を付ける
if [ ! "${dotfiles_dir:0:1}" = "." ]; then
	dotfiles_dir=".$dotfiles_dir"
fi
dotfiles_dir=$HOME/$dotfiles_dir
source $root_dir/misc/install/include/install-sequence.sh
