{ pkgs, lib, config, ... }:

with builtins;
with lib;

let
  cfg = config.baduk.gnugo;
  options = import ./options.nix { inherit pkgs lib cfg; };
in {
  options.baduk.gnugo = options;
  config = mkIf cfg.enable {
    home.packages = [ pkgs.gnugo ];
    baduk.sabaki.engines = forEach cfg.sabakiLevels (level: {
      name = "GNUGo level ${toString level}";
      path =  "${pkgs.gnugo}/bin/gnugo";
      args = ''--mode "gtp" --level ${toString level}'';
    });
  };
}

