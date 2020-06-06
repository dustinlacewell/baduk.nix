{ pkgs, cfg, lib, ... }:

with lib;

let
  dag = import <home-manager/modules/lib/dag.nix> { inherit lib; };
  activation = with dag; txt: dagEntryAfter ["installPackages"] txt;

  engineConfigs = {
    "engines.list" = sort (a: b: a.name < b.name) cfg.engines;
  };

  defaults = importJSON ./settings.json;
  merged = defaults // engineConfigs;
  json = builtins.toJSON merged;
  path = pkgs.writeTextFile {
    name = "sabaki-config";
    text = json;
  };
in activation ''
  rm -fr "~/.config/Sabaki/settings.json"
  cp "${path}" "~/.config/Sabaki/settings.json"
  chown $USER "~/.config/Sabaki/settings.json"
  chmod 700 "~/.config/Sabaki/settings.json"
''

