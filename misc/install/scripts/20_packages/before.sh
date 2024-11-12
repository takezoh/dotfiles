#/bin/bash
set -ex

pip_modules=(
  pip
  neovim
  pygments
)

for mod in ${pip_modules[@]}; do
	pip3 install --upgrade $mod
done
