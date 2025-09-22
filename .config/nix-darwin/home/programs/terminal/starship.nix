{ ... }: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = ''
        [](#9A348E)$os$username[](bg:#DA627D fg:#9A348E)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#86BBD8)$golang$nodejs$rust[](fg:#06969A bg:#33658A)[ ](fg:#33658A)$fill$kubernetes$package$mem_usage$cmd_duration$hostname$time$battery$line_break$character
      '';

      add_newline = false;
      continuation_prompt = "▶▶ ";
      fill.symbol = ".";

      username = {
        show_always = true;
        style_user = "bg:#9A348E fg:#ffffff";
        style_root = "bg:#9A348E fg:#ffffff";
        format = "[ $user ]($style)";
        disabled = false;
      };

      directory = {
        style = "bg:#DA627D fg:#ffffff";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = "󰉍 ";
          Music = " ";
          Pictures = " ";
          Projects = "󰲋 ";
        };
      };

      git_branch = {
        symbol = "";
        style = "bg:#FCA17D fg:#000000";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#FCA17D fg:#000000";
        format = "[$all_status$ahead_behind ]($style)";
        conflicted = "⚡";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        up_to_date = "✓";
        untracked = "?\${count}";
        stashed = "📦\${count}";
        modified = "!\${count}";
        staged = "+\${count}";
        renamed = "»\${count}";
        deleted = "✘\${count}";
      };

      # Programming languages
      golang = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      rust = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
      };

      python = {
        symbol = " ";
        style = "bg:#86BBD8 fg:#000000";
        format = "[ $symbol ($version) ]($style)";
        pyenv_version_name = true;
        python_binary = [ "python3" "python" ];
      };

      kubernetes = {
        symbol = "☸ ";
        style = "fg:#ffffff";
        format = "[ $symbol$context( \\($namespace\\)) ]($style)";
        disabled = false;
      };

      hostname = {
        ssh_only = false;
        style = "fg:#ffffff";
        format = "[ 💻 $hostname ]($style)";
        disabled = false;
      };

      time = {
        disabled = false;
        time_format = "%H:%M:%S";
        style = "fg:#ffffff";
        format = "[  $time ]($style)";
      };

      package = {
        format = "[ 📦 $version ]($style)";
        style = "fg:#ffffff";
        disabled = false;
      };

      memory_usage = {
        disabled = false;
        threshold = 70;
        format = "[ 🐏 $ram ]($style)";
        style = "bg:#f36943 fg:#ffffff";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[ ⏱️ $duration ]($style)";
        style = "yellow bold";
      };

      battery = {
        format = "[ $symbol$percentage ]($style)";
        display = [
          {
            threshold = 20;
            style = "bold fg:#f36943";
          }
          {
            threshold = 50;
            style = "bold fg:#FFCD58";
          }
          {
            threshold = 100;
            style = "bold fg:#33DD2D";
          }
        ];
        full_symbol = "";
        charging_symbol = "⚡";
        discharging_symbol = "";
      };

      line_break.disabled = false;
      character = {
        success_symbol = "[⚡](bold yellow) [>](bold red)";
        error_symbol = "[⚡](bold yellow) [>](bold red)";
        vimcmd_symbol = "[⚡](bold yellow) [>](bold red)";
        format = "$symbol ";
      };
    };
  };
}
