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

  mcpServers = {
    mcpServers = {
      nixos = {
        command = "nix";
        args = [
          "run"
          "github:utensils/mcp-nixos"
          "--"
        ];
      };
    };
  };
in
{
  home.file."CLAUDE.md".source = ./source.CLAUDE.md;
  home.file.".claude/settings.json".text = builtins.toJSON settings;
  home.file.".claude/skills".source = ./skills;
  home.file.".mcp.json".text = builtins.toJSON mcpServers;
}
