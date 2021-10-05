BINDIR ?= /usr/local/bin
LIBDIR := $(CURDIR)/win32yank

TARGET := win32yank
SYMLINK := $(BINDIR)/$(TARGET)
EXECUTABLE := $(LIBDIR)/win32yank.exe

VERSION := v0.0.4
ZIPNAME := win32yank-x64.zip
PACKAGE_URL := "https://github.com/equalsraf/win32yank/releases/download/$(VERSION)/$(ZIPNAME)"

all: $(SYMLINK)

$(SYMLINK): $(EXECUTABLE)
	cp $(EXECUTABLE) $(SYMLINK)
#	sudo ln -snf $(EXECUTABLE) $(SYMLINK).exe
#	sudo ln -snf $(TARGET).exe $(SYMLINK)

$(EXECUTABLE):
	mkdir -p $(LIBDIR)
	cd $(LIBDIR) && curl -LO $(PACKAGE_URL) && unzip $(ZIPNAME) && rm $(ZIPNAME)
	chmod +x $(EXECUTABLE)
