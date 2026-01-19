{
  lib,
  pkgs,
  config,
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

    age.secrets."decluttarr-env".file = ../../../secrets/decluttarr.env.age;

    systemd.services.decluttarr = {
      description = "Decluttarr - Stop stalled downloads and more";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "decluttarr";
        Group = "media";
        WorkingDirectory = "/var/lib/decluttarr";
        # automatically decrypt the secret using Ultan private key
        EnvironmentFile = config.age.secrets."decluttarr-env".path;
        # app expects config to be in ./config/config.yaml relative to cwd ... ever heard of
        # argparse?
        ExecStartPre = ''
          ${pkgs.coreutils}/bin/install -D -m 0640 -o decluttarr -g media ${configPath} /var/lib/decluttarr/config/config.yaml
        '';
        # use custom built pkg overlayed into nixpkgs
        ExecStart = ''
          ${pkgs.decluttarr}/bin/decluttarr
        '';
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
