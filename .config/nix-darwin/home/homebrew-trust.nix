{ ... }:
let
  # Homebrew 6.0 refuses to load formulae/casks from third-party taps unless
  # they are trusted (see `brew trust`). Trust is a consumer-side allowlist
  # stored in ~/.homebrew/trust.json — there is no publisher-side toggle, so a
  # fresh machine must declare it here or `rebuild`'s brew bundle step fails.
  #
  # Keep this list in sync with `homebrew.taps` in system/homebrew.nix.
  trustedTaps = [
    "nikitabobko/tap"
    "marmos91/tap"
    "netbirdio/tap"
  ];
in
{
  home.file.".homebrew/trust.json".text = builtins.toJSON {
    trustedtaps = trustedTaps;
  };
}
