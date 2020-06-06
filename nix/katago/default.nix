{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.baduk.katago;
  options = import ./options.nix { inherit pkgs lib cfg; };
  models = import ./models.nix { inherit pkgs lib cfg; };
  wrappers = import ./wrappers.nix { inherit pkgs lib cfg models; };
  engines = mapAttrsToList (engineName: wrapper: {
    name = "KataGo ${engineName}";
    path = "${wrapper}/bin/${wrapper.name}";
    args = "";
  }) wrappers;
in {
  options.baduk.katago = options;
  config = mkIf cfg.enable {
    home.packages = attrValues wrappers;
    baduk.sabaki.engines = engines;
  };
}

