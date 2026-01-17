{
  config,
  pkgs,
  lib,
  ...
}:

let
  wireguardClientGenerator = pkgs.writeShellApplication {
    name = "generate-wireguard-client";
    runtimeInputs = with pkgs; [ wireguard-tools ];
    text = builtins.readFile ../scripts/generate-wireguard-client.sh;
  };
in
{
  environment.systemPackages = [ wireguardClientGenerator ];
}
