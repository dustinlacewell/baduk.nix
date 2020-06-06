{ pkgs, cfg, lib }:

let
  dag = import <home-manager/modules/lib/dag.nix> { inherit lib; };
  activation = with dag; txt: dagEntryAfter ["installPackages"] txt;

  engineConfigs = {
    "engines.list" = pkgs.lib.sort (a: b: a.name < b.name) cfg.engines;
  };

  defaults = pkgs.lib.importJSON ./settings.json;
  merged = defaults // engineConfigs;
  json = builtins.toJSON merged;
  path = pkgs.writeTextFile {
    name = "sabaki-config";
    text = json;
  };
in activation ''
  rm -fr "/home/ldlework/.config/Sabaki/settings.json"
  cp "${path}" "/home/ldlework/.config/Sabaki/settings.json"
  chown ldlework "/home/ldlework/.config/Sabaki/settings.json"
  chmod 700 "/home/ldlework/.config/Sabaki/settings.json"
''

