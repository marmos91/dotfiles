#!/usr/bin/env bash

if ! is-macos -o ! is-executable brew; then
	echo "Skipped: Homebrew-Cask"
	return
fi

# Install packages

apps=(
	1password
	authy
	bartender
	bettertouchtool
	copilot-for-xcode
	docker
	dropbox
	epic-games
	flux
	google-chrome
	gpg-suite
	handbrake
	istat-menus
	iterm
	logitech-options
	karabiner-elements
	obs
	obsidian
	postman
	slack
	spotify
	tableplus
	the-unarchiver
	teamviewer
	tor-browser
	transmission
	tripmode
	visual-studio-code
	vlc
	wezterm
	whatsapp
	zoom
)

brew install --cask "${apps[@]}"

# Quick Look Plugins (https://github.com/sindresorhus/quick-look-plugins)
# brew cask install qlcolorcode qlstephen qlmarkdown quicklook-json qlprettypatch quicklook-csv qlimagesize webpquicklook suspicious-package
