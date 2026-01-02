{ pkgs, username, hostname, ... }: {
  programs.fish = {
    enable = false; # Disabled by default, set to true if you prefer fish
    plugins = with pkgs.fishPlugins; [
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        };
      }
      {
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "a34b0c2809f665e854d6813dd4b052c1b32a32b4";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];

    shellAliases = {
      bazel = "bazelisk";
      g = "hub";
      gg = "lazygit";
      top = "btop";
      python = "python3";
      cat = "bat";
      ta = "tmux attach";
      ts = "tmux new -s";
      vim = "nvim";
      obsidian = "open -a Obsidian";
      reload-nix =
        "darwin-rebuild switch --flake ~/.config/nix-darwin#${hostname}";
    };

    shellInit = ''
      fish_add_path /etc/profiles/per-user/${username}/bin/
      fish_add_path /opt/homebrew/bin
      fish_add_path /run/current-system/sw/bin
      fish_add_path $HOME/.local/bin
    '';

    interactiveShellInit = ''
      set -U fish_greeting ""
    '';
  };
}
