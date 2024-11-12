#/bin/bash
set -ex

mkdir -p "~/Library/Application Support/Code/User"
ln -snf $ROOTDIR/config/vscode "~/Library/Application Support/Code/User"
