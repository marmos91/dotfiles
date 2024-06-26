#!/usr/bin/env bash

if ! is-macos; then
	echo "Skipped: MacOS custom installations"
	return
fi

set -eo pipefail

if ! directory-exists /Applications/Alacritty.app; then
	wget https://github.com/alacritty/alacritty/releases/download/v0.13.2/Alacritty-v0.13.2.dmg

	hdiutil mount Alacritty-v0.13.2.dmg

	cp -R "/Volumes/Alacritty/Alacritty.app" /Applications

	hdiutil unmount "/Volumes/Alacritty/"

	rm Alacritty-v0.13.2.dmg

	echo "Alacritty installed"

	# Replace Alacritty icon (https://github.com/alacritty/alacritty/issues/3926)

	echo "Replacing Alacritty icon"

	icon_path=/Applications/Alacritty.app/Contents/Resources/alacritty.icns

	if [ ! -f "$icon_path" ]; then
		echo "Can't find existing icon, make sure Alacritty is installed"
		exit 1
	fi

	echo "Backing up existing icon"
	hash="$(shasum $icon_path | head -c 10)"
	mv "$icon_path" "$icon_path.backup-$hash"

	echo "Downloading replacement icon"
	icon_url=https://github.com/hmarr/dotfiles/files/8549877/alacritty.icns.gz
	curl -sL $icon_url | gunzip >"$icon_path"

	touch /Applications/Alacritty.app

	echo "Alacritty icon replaced"

	killall Finder
	killall Dock

else
	echo "Alacritty already installed. Skipping"
fi

if ! directory-exists /Applications/Telegram.app; then
	wget https://osx.telegram.org/updates/Telegram.dmg

	hdiutil mount Telegram.dmg

	cp -R "/Volumes/Telegram/Telegram.app" /Applications

	hdiutil unmount "/Volumes/Telegram/"

	rm Telegram.dmg

	echo "Telegram installed"
else
	echo "Telegram already installed. Skipping"
fi

if ! directory-exists "/Applications/CleanMyMac X.app"; then
	wget https://dl.devmate.com/com.macpaw.CleanMyMac4/CleanMyMacX.dmg

	hdiutil mount CleanMyMacX.dmg

	cp -R "/Volumes/CleanMyMac X/CleanMyMac X.app" /Applications

	hdiutil unmount "/Volumes/CleanMyMac X/"

	rm CleanMyMacX.dmg

	echo "CleanMyMacX installed"

else
	echo "CleanMyMacX already installed"
fi
