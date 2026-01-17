{
  lib,
  pkgs,
  config,
  self,
  ...
}:

{
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
        # use flake output from this repo
        ExecStart = "${self.packages.${pkgs.system}.decluttarr}/bin/decluttarr";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
