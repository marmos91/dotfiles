# Level-1 backup: this machine -> MarcoBackups (NAS) via restic over SFTP/tailnet.
# Multiplatform: shared by the darwin (amaterasu) and the standalone Linux
# home-manager outputs. restic is installed declaratively; the repo is
# initialised idempotently at activation (and by `backup init`); the daily
# backup + weekly forget/prune run via launchd on macOS and systemd user timers
# on Linux. Runtime is .dotfiles/.local/bin/backup, which only backs up paths
# that exist, so the same backup set is safe on every host. restic tags each
# snapshot by hostname, so all machines share one repo and restore per-host.
#
# The NAS host and the repo URL are NOT in this public repo: the `Host` block is
# in the sops `ssh_hosts_config` secret and the URL in `restic_repository` (same
# reasoning as mimir_base_url). The password is the sops `restic_password`.
#
# Level-2 (NAS -> DS3, offsite) runs on the NAS via Task Scheduler, not nix.
{ config, lib, pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  script = "${config.home.homeDirectory}/.dotfiles/.local/bin/backup";
  linkedBin = "${config.home.homeDirectory}/.local/bin/backup";
  logDir = "${config.home.homeDirectory}/.local/state/restic/logs";
  # On macOS restic must use Apple's /usr/bin/ssh so SSH key auth reads the
  # passphrase from the login keychain (UseKeychain) non-interactively. nix's
  # openssh ignores the keychain and prompts, which hangs unattended runs — so
  # it's on the tool PATH only on Linux (there auth goes through the 1Password
  # agent). /usr/bin (hence Apple ssh) is appended to the launchd PATH below.
  binPath = lib.makeBinPath (
    [ pkgs.restic pkgs.coreutils pkgs.bash ] ++ lib.optional (!isDarwin) pkgs.openssh
  );
in
{
  home.packages = [ pkgs.restic ];

  home.file.".config/restic/excludes".source = ./restic-excludes;

  # Common to all hosts: expose `backup` on ~/.local/bin. Deliberately NO
  # network here — an earlier version ran `restic init` over SFTP at this point,
  # which prompted for the SSH key passphrase and hung `rebuild` (and would
  # stall on an unreachable NAS). The repo is created once with `backup init`;
  # it's shared across hosts, so a new machine just points at the existing repo.
  home.activation.restic = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}" "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sfn "${script}" "${linkedBin}"
  '';

  # macOS: launchd agents (daily backup 13:00, weekly prune Sun 14:00).
  # enable is set explicitly: when the agents are defined inside this top-level
  # `launchd.agents = mkIf isDarwin {...}`, home-manager's auto-enable (which
  # keys off a non-empty `config`) doesn't fire and the plists are never
  # written (enable defaults false). gcal works because it's a direct
  # `launchd.agents.<name> = {...}` definition.
  launchd.agents = lib.mkIf isDarwin {
    restic-backup.enable = true;
    restic-backup.config = {
      ProgramArguments = [ "${pkgs.bash}/bin/bash" script "run" ];
      StartCalendarInterval = [ { Hour = 13; Minute = 0; } ];
      RunAtLoad = false;
      StandardOutPath = "${logDir}/backup.log";
      StandardErrorPath = "${logDir}/backup.err.log";
      EnvironmentVariables.PATH = "${binPath}:/usr/bin:/bin";
    };
    restic-prune.enable = true;
    restic-prune.config = {
      ProgramArguments = [ "${pkgs.bash}/bin/bash" script "prune" ];
      StartCalendarInterval = [ { Weekday = 0; Hour = 14; Minute = 0; } ];
      RunAtLoad = false;
      StandardOutPath = "${logDir}/prune.log";
      StandardErrorPath = "${logDir}/prune.err.log";
      EnvironmentVariables.PATH = "${binPath}:/usr/bin:/bin";
    };
  };

  # Linux: systemd user services + timers (same schedule).
  systemd.user = lib.mkIf (!isDarwin) {
    services.restic-backup = {
      Unit.Description = "restic Level-1 backup (this host -> NAS)";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${script} run";
        Environment = [ "PATH=${binPath}" ];
      };
    };
    timers.restic-backup = {
      Unit.Description = "Daily restic backup";
      Timer = { OnCalendar = "*-*-* 13:00:00"; Persistent = true; };
      Install.WantedBy = [ "timers.target" ];
    };
    services.restic-prune = {
      Unit.Description = "restic weekly forget + prune";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash ${script} prune";
        Environment = [ "PATH=${binPath}" ];
      };
    };
    timers.restic-prune = {
      Unit.Description = "Weekly restic prune";
      Timer = { OnCalendar = "Sun *-*-* 14:00:00"; Persistent = true; };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
