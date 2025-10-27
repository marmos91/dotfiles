{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Fast loading - scan timeout
      scan_timeout = 10;

      # Catppuccin Mocha palette
      palette = "catppuccin_mocha";

      # Format - keep it clean and essential
      format = "$username$hostname$directory$git_branch$git_status$nix_shell$docker_context$golang$rust$nodejs$python$character";

      # Right prompt with time and command duration
      right_format = "$kubernetes$cmd_duration$time";

      # Character - different for success/error
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      # Directory - truncate long paths
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold sapphire";
      };

      # Git branch
      git_branch = {
        symbol = " ";
        style = "bold mauve";
        format = "on [$symbol$branch]($style) ";
      };

      # Git status - show when dirty
      git_status = {
        conflicted = "🏳";
        ahead = "⇡\${count}";
        behind = "⇣\${behind_count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        modified = "!";
        staged = "[+\($count\)](green)";
        style = "bold yellow";
      };

      # Nix shell indicator
      nix_shell = {
        symbol = "󱄅 ";
        style = "bold blue";
        format = "via [$symbol$state]($style) ";
      };

      # Docker context
      docker_context = {
        symbol = " ";
        style = "bold sky";
        format = "via [$symbol$context]($style) ";
        only_with_files = true;
      };

      # Kubernetes context
      kubernetes = {
        disabled = false;
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$context]($style) ";
      };

      # Go
      golang = {
        symbol = " ";
        style = "bold teal";
        format = "via [$symbol($version )]($style)";
      };

      # Rust
      rust = {
        symbol = " ";
        style = "bold peach";
        format = "via [$symbol($version )]($style)";
      };

      # Node.js
      nodejs = {
        symbol = " ";
        style = "bold green";
        format = "via [$symbol($version )]($style)";
      };

      # Python
      python = {
        symbol = " ";
        style = "bold yellow";
        format = "via [$symbol($version )]($style)";
      };

      cmd_duration = {
        format = "took [$duration](bold yellow) ";
        style = "bold yellow";
      };

      # Time
      time = {
        disabled = false;
        format = "[$time](bold lavender)";
        time_format = "%T";
        style = "bold lavender";
      };

      # Catppuccin Mocha color definitions
      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
      };
    };
  };
}
