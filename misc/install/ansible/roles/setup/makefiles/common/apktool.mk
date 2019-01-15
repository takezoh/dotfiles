TARGET := apktool.jar
LIB_DIR := $(CURDIR)/apktool

VERSION := 2.3.4
LIB_NAME := "apktool_$(VERSION).jar"
LIB_URL := "https://bitbucket.org/iBotPeaches/apktool/downloads/$(LIB_NAME)"

$(LIB_DIR)/$(TARGET): $(LIB_DIR)/$(LIB_NAME)
	ln -snf $(LIB_DIR)/$(LIB_NAME) $(LIB_DIR)/$(TARGET)

$(LIB_DIR)/$(LIB_NAME):
	mkdir -p $(LIB_DIR)
	cd $(LIB_DIR) && curl -LO $(LIB_URL)
