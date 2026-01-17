{
  lib,
  pkgs,
  config,
  self,
  system,
  ...
}:

let
  configPath = pkgs.writeTextFile {
    name = "decluttarr.yaml";
    text = config.services.decluttarr.settings;
  };
in
{
  options.services.decluttarr = {
    settings = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "YAML literal to be written to config file";
    };
  };

  config = lib.mkIf config.services.mediaStack.enable {
    users.users.decluttarr = {
      isSystemUser = true;
      group = "media";
      home = "/var/lib/decluttarr";
      createHome = true;
    };

    systemd.services.decluttarr = {
      description = "Decluttarr - Stop stalled downloads and more";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "decluttarr";
        Group = "media";
        WorkingDirectory = "/var/lib/decluttarr";
        EnvironmentFile = "/root/secrets/decluttarr.env";
        # app expects config to be in ./config/config.yaml relative to cwd ... ever heard of
        # argparse?
        ExecStartPre = ''
          ${pkgs.coreutils}/bin/install -D -m 0640 -o decluttarr -g media ${configPath} /var/lib/decluttarr/config/config.yaml
        '';
        # use flake output from this repo
        ExecStart = ''
          ${self.packages.${system}.decluttarr}/bin/decluttarr
        '';
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
