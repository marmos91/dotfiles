# GnuPG user config. Owns ~/.gnupg/gpg.conf, gpg-agent.conf and dirmngr.conf;
# nothing else in this repo touches ~/.gnupg.
#
# This used to be three stowed files. Stow folded the directory, so `stow .`
# made ~/.gnupg a symlink into the git working tree and GnuPG wrote its key
# material (private-keys-v1.d, trustdb.gpg, random_seed, sockets) inside the
# checkout. .stowrc now ignores .gnupg, and the activation below turns an
# existing folded ~/.gnupg symlink back into a real 0700 directory (moving the
# key material out of the checkout) before home-manager links these files.
#
# Values are deliberately short/resident-free: the agent keeps an unlocked
# signing key for the working day at most (600/7200), refuses an external
# cache, and verification never fetches a key on its own — a remote signature
# must not be able to choose which host gpg contacts (auto-key-retrieve would
# honour a signer-supplied keyserver URL, which can downgrade HKPS to plaintext
# HTTP).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # On macOS the pinentry comes from the gpg-suite cask. The path is checked on
  # this host: /Applications holds "GPG Keychain.app", not "GPG Suite.app", and
  # the binary lives under /usr/local/MacGPG2/libexec/. Do not derive it from
  # the cask name. On Linux use pinentry-curses (`pinentry` itself was removed
  # from nixpkgs and curses is the variant that also works over SSH);
  # interpolating the store path below is what puts it in the closure.
  pinentry =
    if isDarwin then
      "/usr/local/MacGPG2/libexec/pinentry-mac.app/Contents/MacOS/pinentry-mac"
    else
      "${pkgs.pinentry-curses}/bin/pinentry";
in
{
  home.file = {
    ".gnupg/gpg.conf" = {
      force = true;
      text = ''
        no-emit-version
        default-key ABFD92D353CD439DEC3CDF32E21700784B22779D
        auto-key-locate local
        keyserver-options no-honor-keyserver-url
      '';
    };

    ".gnupg/gpg-agent.conf" = {
      force = true;
      text = ''
        default-cache-ttl 600
        max-cache-ttl 7200
        no-allow-external-cache
        pinentry-program ${pinentry}
      '';
    };

    ".gnupg/dirmngr.conf" = {
      force = true;
      text = ''
        keyserver hkps://keys.openpgp.org
      '';
    };
  };

  # Runs before linkGeneration: otherwise the links would land inside a folded
  # ~/.gnupg (in the git checkout), or fail on a dangling one. Also creates the
  # homedir 0700 on a fresh machine, since gpg rejects an unsafe homedir.
  home.activation.gnupgHome = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    gnupg="${config.home.homeDirectory}/.gnupg"
    if [ -L "$gnupg" ]; then
      target=$(cd "$gnupg" 2>/dev/null && pwd -P) || target=
      run rm "$gnupg"
      if [ -n "$target" ]; then run mv "$target" "$gnupg"; fi
    fi
    run mkdir -m 700 -p "$gnupg"
    run chmod 700 "$gnupg"
  '';
}
