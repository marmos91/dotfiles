{ ... }: {
  # Common aliases that can be shared between shells
  home.shellAliases = {
    # Git shortcuts
    gst = "git status";
    gco = "git checkout";
    gcb = "git checkout -b";
    gaa = "git add --all";
    gcm = "git commit -m";
    gp = "git push";
    gl = "git pull";

    # Directory navigation
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";

    # List files
    la = "ls -la";
    ll = "ls -l";

    # Safety aliases
    rm = "rm -i";
    cp = "cp -i";
    mv = "mv -i";
  };
}
