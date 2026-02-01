{
  config,
  pkgs,
  lib,
  ...
}:

let
  privateKeyFile = config.age.secrets.ultan-wg-key.path;
  wireguardClientGenerator = pkgs.writeShellApplication {
    name = "generate-wireguard-client";
    runtimeInputs = with pkgs; [ wireguard-tools ];
    text = ''
      # injected by Nix build
      WG_PRIVATE_KEY_PATH=${privateKeyFile}

      ${builtins.readFile ../../scripts/generate-wireguard-client.sh}
    '';
  };
in
{
  environment.systemPackages = [ wireguardClientGenerator ];
}
