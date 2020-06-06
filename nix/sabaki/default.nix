{ config, pkgs, lib, ... }@args:

with lib;

let
  cfg = config.baduk.sabaki;
  options = import ./options.nix { inherit pkgs lib cfg; };
  sabaki = import ./package.nix { inherit pkgs lib cfg; };
in {
  options.baduk.sabaki = options;
  config = mkIf cfg.enable {
    home.packages = [ sabaki ];
  };
}

