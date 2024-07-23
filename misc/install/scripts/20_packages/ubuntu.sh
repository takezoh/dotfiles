#/bin/bash
set -ex

ubuntu_repos=(
  ppa:git-core/ppa
  # ppa:neovim-ppa/unstable
)

ubuntu_deb_packages=(
  # https://github.com/BurntSushi/ripgrep/releases/download/0.9.0/ripgrep_0.9.0_amd64.deb
)

ubuntu_packages=(
  python-is-python3
  python3-pip
  # linuxbrew-wrapper
  lv
  tree
  wget
  curl

  zsh
  git
  tig

  # make
  cmake

  nkf
  source-highlight

  global
  zip

  build-essential
  zlib1g-dev
  libffi-dev
  libssl-dev
  libclang-dev
  # libmysqlclient-dev
  # mysql-client
  # mysql-server
  # redis-server

  libffi-dev

  g++-i686-linux-gnu
  g++-arm-linux-gnueabi
  g++-x86-64-linux-gnux32
  g++-mingw-w64
)

brew_formulas=(
  fzf
  peco
  ripgrep
  bat
  pandoc
  awscli
  neovim
  python
  python3

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

  jadx
  dex2jar
)


	# sudo apt install -y python3 python3-pip
	# sudo apt update -y
	# sudo apt install -y software-properties-common
	# sudo apt update -y

# if ! type brew >/dev/null 2>&1; then
# if [ -d /home/linuxbrew/.linuxbrew ]; then
if [ ! -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
	sudo apt install -y build-essential curl file git
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

for repo in ${ubuntu_repos[@]}; do
	sudo add-apt-repository $repo
done

for repo in ${ubuntu_deb_packages[@]}; do
	curl $repo -o /tmp/repo.deb
	sudo apt-get install /tmp/repo.deb
done

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install ${ubuntu_packages[@]}

brew update
brew upgrade
brew install ${brew_formulas[@]}
