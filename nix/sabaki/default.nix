{ config, pkgs, lib, ... }@args:

with lib;

let
  cfg = config.baduk.sabaki;
  options = import ./options.nix { inherit pkgs lib cfg; };
  sabaki = import ./package.nix { inherit pkgs lib cfg; };
  sabakiConfig = import ./config.nix { inherit pkgs lib cfg; };
in {
  options.baduk.sabaki = options;
  config = mkMerge [
    (mkIf cfg.enable { home.packages = [ sabaki ]; })
    (mkIf ((length cfg.engines) > 0) { home.activation.sabaki-config = sabakiConfig; })
  ];
}

