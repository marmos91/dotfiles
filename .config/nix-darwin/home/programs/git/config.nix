{ pkgs, lib, config, ... }:
let
  # Local ed25519 signing key (lives at ~/.ssh/id_ed25519). Git signs via the
  # native ssh-agent / ssh-keygen — no 1Password unlock required.
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHC3Xm+j0b1OJdfk2hmqPNxnbvh2knC25EX2wEtSB5DK";
  # Previous 1Password-managed RSA key. Kept in allowed_signers so historical
  # commits signed with it still verify locally via `git log --show-signature`.
  legacySigningKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1Z1G84m2eZAGLJnXNiItcqUvaL36gG2/bam73es6wDhDpdQwhb1+1kBCf3Yqq98is7zACuzKgFhrLkKPWs+1TSTCOXrL0he6MNHUdpiYhZewKNMg4A8+RkpBgJpekQr0ulhhnH7aWKZ1x+qIBc/uPOumEG0SnJM7mzoZ1KO+M2Djk64ofXOeODgCyXut/8wdpRVXjv9fttdvyQOoTFPgLqzsBCnlRR1lo3mo+AffLjwnRdH2UThW4cDiQnPCfLUAopFobC8P8plNnBdrjl3GOaCcGbbgphiJVJ9Gfb6gPMvMkQjnGlCfhvxfvCya6D0oZGA/oMZMU4+qePaSJKeyYatIdHSWtD8cn3USLIIRe0NBzsgpsluxuqLN/wYWkLGZ8jWVsPBUYWl+0V2jNmJNrk0AZwgHuhpegBU+rpCR4+LYvdB43qSHvT1e2Bjz83M5Sqbf94SpfaV0UjiUSR4HhVdmeftIrIRJLc59MIRGfQvaiII5ozCJu4nNTJa/YklM=";
  userEmail = "m.marmos@gmail.com";
in
{
  # allowed_signers: trust both the active key and the legacy 1Password key for
  # verification of past commits.
  home.file.".config/git/allowed_signers".text = ''
    ${userEmail} ${signingKey}
    ${userEmail} ${legacySigningKey}
  '';

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      key = signingKey;
      format = "ssh";
    };

    settings = {
      user = {
        name = "marmos91";
        email = userEmail;
      };

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        ca = "commit --amend";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
        ls-subtrees = "!\"git log | grep git-subtree-dir | awk '{ print $2 }'";

        # More useful aliases
        hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
        type = "cat-file -t";
        dump = "cat-file -p";
        recent = "branch --sort=-committerdate";
      };

      github.user = "marmos91";
      hub.protocol = "ssh";

      # Core settings
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;

      # Better diff and merge
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3";

      # SSH signing with the native toolchain (ssh-keygen -Y sign). No
      # `gpg.ssh.program` override — falls back to the default, which resolves
      # the signing key through ssh-agent / ~/.ssh.
      gpg.format = "ssh";
      "gpg \"ssh\"".allowedSignersFile = "~/.config/git/allowed_signers";

      # Git LFS
      filter.lfs = {
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
        required = true;
      };

      # Include local config
      include.path = "~/.config/git/config.local";

    };
  };
}
