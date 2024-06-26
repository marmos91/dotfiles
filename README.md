# marmos91 .files for macOS

Personal dotfiles repository.

![result](./assets/setup.png)

## Highlights

- [Neovim](https://neovim.io/) configured through a custom lua configuration
- [Alacritty](https://alacritty.org/), [Kitty](https://sw.kovidgoyal.net/kitty/) and [iTerm2](https://iterm2.com/) installed (Alacritty used as main terminal emulator)
- Fish as default shell configured with Fisher
- Powerful terminal management through [Tmux](https://github.com/tmux/tmux/wiki)
- Support for Apple Silicon and Intel Macs

## How to install

First of all clone this repository

```bash
git clone https://github.com/marmos91/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
git submodule init
git submodule update
```

Run the following command

```bash
chmod +x ~/.dotfiles/install.sh
~/.dotfiles/install.sh
```

All the needed tools will be downloaded automatically.

### Note

You may have to restart neovim a few times for all the plugin to install correctly.

## Customization

You are free to modify my configuration to suit your needs.

Here is a list of places to start:

- [`install/brew-cask.sh`](./install/brew-cask.sh): contains all the applications
- [`install/brew.sh`](./install/brew.sh): contains all the command line utilities
- [`install/fonts.sh`](./install/fonts.sh): contains all the custom fonts
- [`install/mas.sh`](./install/mas.sh): contains all the Mac App Store applications
- [`install/npm.sh`](./install/npm.sh): contains all the node command line utilities

The config folder contains all the configurations of the applications we are going to install.
The most interesting path is definitely [`config/nvim/lua/custom`](./config/nvim/lua/custom) where you can find my configuration for _neovim_.

Finally, the [`dotfiles`](./dotfiles/) folder contains all my personal dotfiles, feel free to modify them as you see fit.

## Acknowledgements

For many of the configurations you find I have taken cues from other amazing repositories.
I link them below because they can be inspiration for you as well:

- [https://github.com/joshukraine/dotfiles](https://github.com/joshukraine/dotfiles)
- [https://github.com/mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles)
- [https://github.com/alrra/dotfiles](https://github.com/alrra/dotfiles)
- [https://github.com/ThePrimeagen/.dotfiles](https://github.com/ThePrimeagen/.dotfiles)

## Setup iTerm color scheme and custom fonts

To install iTerm color schema and custom fonts open iTerm preferences and go to the `Profile` tab.
Under the `Text` tab select the `JetBrainsMono Nerd Font` font

![iterm-text](./assets/iterm-text.png)

## Enjoy

Enjoy your new terminal 😊

## License

[MIT LICENSE](./LICENSE)
