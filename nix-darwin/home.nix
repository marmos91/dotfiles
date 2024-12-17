{ config, pkgs, lib, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "marmos91";
  home.homeDirectory = "/Users/marmos91";

  home.sessionPath = [ "/run/current-system/sw/bin" "$HOME/.nix-profile/bin" ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "OneHalfDark";
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batpipe
      batgrep
      batwatch
    ];
  };

  programs.btop = {
    enable = true;
    settings = {
      theme = "catppuccin";
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    enableZshIntegration = true;
    git = true;
  };

  programs.zsh = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };

  programs.git = {
    enable = true;

    userName = "marmos91";
    userEmail = "m.marmos@gmail.com";

    signing = {
      signByDefault = true;
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1Z1G84m2eZAGLJnXNiItcqUvaL36gG2/bam73es6wDhDpdQwhb1+1kBCf3Yqq98is7zACuzKgFhrLkKPWs+1TSTCOXrL0he6MNHUdpiYhZewKNMg4A8+RkpBgJpekQr0ulhhnH7aWKZ1x+qIBc/uPOumEG0SnJM7mzoZ1KO+M2Djk64ofXOeODgCyXut/8wdpRVXjv9fttdvyQOoTFPgLqzsBCnlRR1lo3mo+AffLjwnRdH2UThW4cDiQnPCfLUAopFobC8P8plNnBdrjl3GOaCcGbbgphiJVJ9Gfb6gPMvMkQjnGlCfhvxfvCya6D0oZGA/oMZMU4+qePaSJKeyYatIdHSWtD8cn3USLIIRe0NBzsgpsluxuqLN/wYWkLGZ8jWVsPBUYWl+0V2jNmJNrk0AZwgHuhpegBU+rpCR4+LYvdB43qSHvT1e2Bjz83M5Sqbf94SpfaV0UjiUSR4HhVdmeftIrIRJLc59MIRGfQvaiII5ozCJu4nNTJa/YklM=";
    };

    extraConfig = {
      "github" = {
        user = "marmos91";
      };
      "hub" = {
        protocol = "ssh";
      };
      "pull" = {
        rebase = true;
      };
      "fetch" = {
        prune = true;
      };
      "push" = {
        autoSetupRemote = true;
      };
      "gpg" = {
        format = "ssh";
        "ssh" = {
          program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      "filter" = {
        "lfs" = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
      };
      "alias" = {
        "ls-subtrees" = "!\"git log | grep git-subtree-dir | awk '{ print $2 }'";
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    DOTFILES_DIR = "$HOME/.dotfiles";
    OBSIDIAN_VAULTS_DIR = "$HOME/vaults";
    GPG_TTY = "$(tty)";
    GITHUB_USERNAME = "marmos91";
    BACKUP_VOLUME = "/Volumes/BackupMarco";
    PNPM_HOME = "$HOME/Library/pnpm";

    # GIT_USERNAME = ''${builtins.exec [ "op read op://Private/zhbcl6lev6deprtnom5lj2tily/username" ]}'';
    # GIT_EMAIL = ''${builtins.exec [ "op read op://Private/zlghqxn5oj6muxylw6lcctq4te/email" ]}'';
    # GIT_SIGNING_KEY = ''${builtins.exec [ "op read op://Private/icvlyica2bqisvldzi3exj5kau/password" ]}'';
  };

  # Configure fish shell
  programs.fish = {
    enable = true;
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
      {
        name = "fzf-fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
      {
        name = "done";
        src = pkgs.fetchFromGitHub {
          owner = "franciscolourenco";
          repo = "done";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
      {
        name = "nvm";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "nvm.fish";
          rev = "2419963866788815743";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];
    shellAliases = {
      g = "hub";
      gg = "lazygit";
      top = "btop";
      python = "python3";
      pinentry = "pinentry-mac";
      cat = "bat";
      vim = "nvim";
      obsidian = "open -a Obsidian";
      reload-nix = "darwin-rebuild switch --flake ~/.config/nix-darwin#amaterasu";
    };
    interactiveShellInit = ''
      set -U fish_greeting ""
      neofetch
    '';
  };

  home.packages = with pkgs; [
    _1password-cli
    awscli
    bazelisk
    btop
    buildifier
    cmake
    commitlint
    diff-so-fancy
    ffmpeg
    fzf
    gh
    hub
    git-lfs
    go-task
    go_1_23
    k9s
    kubectl
    kubectx
    lazygit
    neofetch
    neovim
    nixfmt-classic
    reattach-to-user-namespace
    ripgrep
    rustup
    stow
    tilt
    tldr
    tree
    wget
    yt-dlp
  ];
}
