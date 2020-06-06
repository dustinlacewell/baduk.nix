{ config, pkgs, ... }:

with pkgs.lib;

let
  cfg = config.baduk.sabaki;
in {
  options.baduk.sabaki = mkEnableOption "sabaki";
  config = mkIf cfg.enable {
    home.packages = [ pkgs.hello ];
  };
}

