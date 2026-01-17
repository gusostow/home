{
  lib,
  pkgs,
  config,
  self,
  ...
}:

let
  configPath = pkgs.writeTextFile config.services.decluttarr.settings;
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

    environment.etc."decluttarr/config.yaml".source = configPath;

    systemd.services.decluttarr = {
      description = "Decluttarr - Stop stalled downloads and more";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "decluttarr";
        Group = "media";
        # use flake output from this repo
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '
            ${pkgs.coreutils}/bin/env \
              SONARR_API_KEY=$(cat $CREDENTIALS_DIRECTORY/sonarr-key) \
              RADARR_API_KEY=$(cat $CREDENTIALS_DIRECTORY/radarr-key) \
              ${self.packages.${pkgs.system}.decluttarr}/bin/decluttarr
          '
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        LoadCredential = [
          "sonarr-key:/root/secrets/sonarr-api-key"
          "radarr-key:/root/secrets/radarr-api-key"
        ];
      };
    };
  };
}
