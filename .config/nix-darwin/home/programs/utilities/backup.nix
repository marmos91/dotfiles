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
  binPath = lib.makeBinPath [ pkgs.restic pkgs.openssh pkgs.coreutils pkgs.bash ];
in
{
  home.packages = [ pkgs.restic ];

  home.file.".config/restic/excludes".source = ./restic-excludes;

  # Common to all hosts: expose `backup` on ~/.local/bin and init the repo
  # idempotently (best-effort; skipped cleanly if the NAS is unreachable or sops
  # hasn't rendered the secrets yet, so it never fails the rebuild).
  home.activation.restic = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${logDir}" "${config.home.homeDirectory}/.local/bin"
    $DRY_RUN_CMD ln -sfn "${script}" "${linkedBin}"
    repo="${config.home.homeDirectory}/.config/restic/repository"
    pass="${config.home.homeDirectory}/.config/restic/password"
    if [ -r "$repo" ] && [ -r "$pass" ]; then
      PATH="${binPath}:$PATH" RESTIC_REPOSITORY="$(cat "$repo")" RESTIC_PASSWORD_FILE="$pass" \
        ${pkgs.restic}/bin/restic cat config >/dev/null 2>&1 \
      || PATH="${binPath}:$PATH" RESTIC_REPOSITORY="$(cat "$repo")" RESTIC_PASSWORD_FILE="$pass" \
         $DRY_RUN_CMD ${pkgs.restic}/bin/restic init >/dev/null 2>&1 || true
    fi
  '';

  # macOS: launchd agents (daily backup 13:00, weekly prune Sun 14:00).
  launchd.agents = lib.mkIf isDarwin {
    restic-backup.config = {
      ProgramArguments = [ "${pkgs.bash}/bin/bash" script "run" ];
      StartCalendarInterval = [ { Hour = 13; Minute = 0; } ];
      RunAtLoad = false;
      StandardOutPath = "${logDir}/backup.log";
      StandardErrorPath = "${logDir}/backup.err.log";
      EnvironmentVariables.PATH = "${binPath}:/usr/bin:/bin";
    };
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
