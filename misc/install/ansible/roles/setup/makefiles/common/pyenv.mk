BINDIR ?= /usr/local/bin

TARGET := pyenv pyenv-virtualenv
GITREPO := .git/config

all: $(addprefix $(BINDIR)/, $(TARGET))

$(BINDIR)/%: %/$(GITREPO)
	cd $* && git pull -f origin master
	sudo ln -snf $(CURDIR)/$*/bin/$* $(BINDIR)/$*

pyenv/$(GITREPO):
	git clone https://github.com/yyuu/pyenv.git

pyenv-virtualenv/$(GITREPO):
	git clone https://github.com/pyenv/pyenv-virtualenv.git
