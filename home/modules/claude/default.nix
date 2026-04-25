{
  config,
  lib,
  pkgs,
  ...
}:

let
  settings = {
    alwaysThingEnabled = false;
  };
in
{
  home.file."~/.claude/settings.json".text = builtins.toJSON settings;
}
