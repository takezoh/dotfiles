#/bin/bash
set -ex

mkdir -m 700 -p $HOME/.ssh
mkdir -m 755 -p $HOME/.config
mkdir -m 755 -p $HOME/.local
mkdir -m 755 -p $HOME/.local/share/zsh

for d in `command ls $ROOTDIR/config`; do
	ln -snf $ROOTDIR/config/$d $HOME/.config/$d
done

for d in `command ls $ROOTDIR/config/non-xdg`; do
	ln -snf $ROOTDIR/config/non-xdg/$d $HOME/.$d
done

ln -snf $ROOTDIR/config/zsh/.zshenv $HOME/.zshenv
ln -snf $ROOTDIR/config/nvim/init.vim $HOME/.vimrc
ln -snf $ROOTDIR/config/ssh/config $HOME/.ssh/config
