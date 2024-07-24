DOWNLOAD_DIR := $(shell wslpath -au `cmd.exe /d /c echo %USERPROFILE%/Downloads`)
INSTALL_PREFIX := $(shell wslpath -au `cmd.exe /d /c echo %LOCALAPPDATA%/wsltty`)
EXECUTABLE := $(INSTALL_PREFIX)/bin/mintty.exe

VERSION := 3.6.1.2
ARCH=x86_64
INSTALLER := wsltty-$(VERSION)-$(ARCH)-install.exe
INSTALLER_URL := "https://github.com/mintty/wsltty/releases/download/$(VERSION)/$(INSTALLER)"

all: $(EXECUTABLE)

$(EXECUTABLE):
	cd $(DOWNLOAD_DIR) && rm -f $(INSTALLER) && curl -LO $(INSTALLER_URL) && cmd.exe /c start $(INSTALLER)
	cmd.exe /d /c `wslpath -aw $(ROOT_DIRECTORY)/misc/install/install-terminal-launcher-windows.js`
