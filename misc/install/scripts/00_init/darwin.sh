#/bin/bash
set -ex

defaults write com.apple.finder AppleShowAllFiles TRUE
defaults write com.apple.desktopservices DSDontWriteNetworkStores TRUE
killall Finder
