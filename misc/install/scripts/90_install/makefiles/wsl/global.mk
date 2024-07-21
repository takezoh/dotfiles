TARGET := global.exe gtags.exe
PREFIX := $(shell wslpath -au `cmd.exe /d /c echo "%LOCALAPPDATA%/Microsoft/WindowsApps"`)
TEMP := $(shell wslpath -au `cmd.exe /d /c echo "%TEMP%"`)

ZIP_NAME := glo663wb
DOWNLOAD_URL := "http://adoxa.altervista.org/global/dl.php?f=$(ZIP_NAME).zip"


$(addprefix $(PREFIX)/, $(TARGET)):
	rm -rf $(TEMP)/$(ZIP_NAME)
	mkdir -p $(TEMP)/$(ZIP_NAME)
	curl -L $(DOWNLOAD_URL) -o $(TEMP)/$(ZIP_NAME)/archive.zip
	cd $(TEMP)/$(ZIP_NAME) && unzip archive.zip && cd bin && mv $(TARGET) $(PREFIX)
