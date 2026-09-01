{ pkgs, lib, config, ... }:
let
  # Local ed25519 signing key. The private half lives at ~/.ssh/id_ed25519,
  # restored from 1Password by `op-ssh-restore`.
  #
  # `signing.key` must be the PATH, not the literal public key: given a literal
  # key git calls `ssh-keygen -Y sign -U`, which demands an agent holding the
  # private half and fails with "Couldn't find key in agent?". Given a path it
  # reads the file directly — no agent, no 1Password prompt.
  signingKeyFile = "~/.ssh/id_ed25519";
in
{
  # Identities and allowed_signers are sops secrets (`git_identity`,
  # `git_identity_work`, `git_allowed_signers` in home/secrets), so the email
  # addresses stay out of this public repo. sops decrypts them to
  # ~/.config/git/ at activation; git reads them at runtime via `includes`.
  #
  # The default identity is the GitHub noreply address, so no real address is
  # published in commit metadata. Work repos under ~/Projects/cubbit still get
  # the Cubbit address, which their org needs for attribution.
  #
  # allowed_signers lists both the active ed25519 key and the legacy
  # 1Password RSA key under every address ever used — noreply, personal and
  # work — so older signed commits still verify via `git log --show-signature`.
  # A signer is matched by the commit's email, not by the key alone.

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;

    signing = {
      signByDefault = true;
      key = signingKeyFile;
      format = "ssh";
    };

    # Order matters: the personal identity applies everywhere, then work repos
    # override the address under ~/Projects/cubbit. Same signing key, so
    # nothing else has to change per-repo.
    includes = [
      { path = "~/.config/git/identity"; }
      {
        condition = "gitdir:~/Projects/cubbit/";
        path = "~/.config/git/identity-work";
      }
    ];

    settings = {
      user = {
        # The name commits are actually authored with — an unmanaged
        # ~/.gitconfig used to override this with "Marco Moschettini".
        # `email` deliberately lives in the sops-backed includes above.
        name = "Marco Moschettini";
      };

      # Written by `gh auth login` into ~/.gitconfig; declared here so the
      # unmanaged file isn't the only place they live.
      "credential \"https://github.com\"".helper = "!gh auth git-credential";
      "credential \"https://gist.github.com\"".helper = "!gh auth git-credential";

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
      # `gpg.ssh.program` override — the default reads user.signingkey, which
      # is a path to the on-disk key, so no agent is involved.
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
