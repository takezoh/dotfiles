#/bin/bash
set -ex

sudo mkdir -p /usr/local/opt && chown -R $USER:$USER /usr/local/opt

common_makefiles=(
  common/apktool
  common/pyenv
)

for mk in ${common_makefiles[@]}; do
	BINDIR=/usr/local/bin ROOT_DIRECTORY=$ROOTDIR make -f $ROOTDIR/misc/install/scripts/90_install/makefiles/$mk.mk -C /usr/local/opt
done

# rust cargo
curl https://sh.rustup.rs -sSf | sh
