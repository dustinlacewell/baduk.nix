{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.baduk.leela-zero;
  options = import ./options.nix { inherit pkgs lib cfg; };
  models = import ./models.nix { inherit pkgs lib cfg; };
  wrappers = import ./wrappers.nix { inherit pkgs lib cfg models; };
  engines = mapAttrsToList (engineName: wrapper: {
    name = "Leela Zero ${engineName}";
    path = "${wrapper}/bin/${wrapper.name}";
    args = "";
  }) wrappers;

in {
  options.baduk.leela-zero = options;
  config = mkIf cfg.enable {
    home.packages = attrValues wrappers;
    baduk.sabaki.engines = engines;
  };
}
