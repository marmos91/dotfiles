# marmos91 .files for macOS

Personal dotfiles repository based on Nix Darwin, Home Manager and Stow.

![result](./assets/setup.png)

## Highlights

- [Neovim](https://neovim.io/) configured through a custom lua configuration
- [Ghostty](https://github.com/ghostty-org/ghostty) as terminal emulator. [Wezterm](https://wezfurlong.org/wezterm/index.html) also installed.
- Fish as default shell (Nushell also installed)
- Powerful terminal management through [Tmux](https://github.com/tmux/tmux/wiki)
- Support for Apple Silicon and Intel Macs

## How to install

First of all, clone this repository

```bash
git clone https://github.com/marmos91/dotfiles.git ~/.dotfiles
```

Run the following command

```bash
chmod +x ~/.dotfiles/setup.sh
~/.dotfiles/setup.sh
```

All the needed tools will be downloaded automatically.

### Note

You may have to restart neovim a few times for all the plugin to install correctly.

## Customization

You are free to modify my configuration to suit your needs.

Here is a list of places to start:

The config folder contains all the configurations of the applications we are going to install.
The most interesting path is definitely [`config/nvim`](./.config/nvim) where you can find my configuration for _neovim_.

## Enjoy

Enjoy your new terminal 😊

## License

[MIT LICENSE](./LICENSE)
