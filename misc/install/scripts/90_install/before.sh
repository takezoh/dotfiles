#/bin/bash
set -ex

case "$OSTYPE" in
darwin*)
	sudo mkdir -p /usr/local/opt && chown -R $USER:staff /usr/local/opt
	;;
*)
	sudo mkdir -p /usr/local/opt && chown -R $USER:$USER /usr/local/opt
	;;
esac

common_makefiles=(
  common/apktool
  common/pyenv
)

for mk in ${common_makefiles[@]}; do
	BINDIR=/usr/local/bin ROOT_DIRECTORY=$ROOTDIR make -f $ROOTDIR/misc/install/makefiles/$mk.mk -C /usr/local/opt
done

# rust cargo
if [ ! -f ~/.cargo/bin/cargo ]; then
	curl https://sh.rustup.rs -sSf | sh
fi
