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
  home.file."CLAUDE.md".source = ./source.CLAUDE.md;
  home.file.".claude/settings.json".text = builtins.toJSON settings;
  home.file.".claude/skills".source = ./skills;
}
