{ pkgs, lib, cfg, models }:

with lib;
with builtins;

let
  buildLeelaZero = size:
    if size == 19 then pkgs.leela-zero else
      (pkgs.leela-zero.overrideAttrs (old: rec {
        name = "leelaz-${version}";
        version = "${toString size}x${toString size}";
        patchPhase = pkgs.lib.optionalString (size != "19") ''
          #!${pkgs.stdenv.shell}
          sed -i -e 's/BOARD_SIZE = 19/BOARD_SIZE = ${toString size}/' src/config.h
        '';
      }));

  mkLeelaZero = { name, size, model, visits, playouts }:
    let
      package = buildLeelaZero size;
      playoutArg = optionalString (playouts != null)
        "-p ${toString playouts}";
      visitsArg = optionalString (visits != null)
        "-v ${toString visits}";
      ponderArg = optionalString ((playouts != null) || (visits != null))
        "--noponder";
      args = "-g ${playoutArg} ${visitsArg} ${ponderArg} -w ${model}";
    in pkgs.writeScriptBin "leelaz-${name}" ''
      ${package}/bin/leelaz ${args} $@
    '';

in mapAttrs (name: variant: mkLeelaZero {
  inherit name;
  inherit (variant) size visits playouts;
  model = models."${name}";
}) cfg.variants
