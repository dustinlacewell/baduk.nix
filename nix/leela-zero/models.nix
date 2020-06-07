{ pkgs, lib, cfg }:

with lib;
with builtins;

let
  models = mapAttrs (name: args: pkgs.fetchurl args) cfg.models;

  converterPython = pkgs.python3.withPackages (ps: [ ps.numpy ps.scipy ]);

  convertNetwork = model: size:
    if size == 19 then
      model
    else
      pkgs.runCommand "${toString size}-${toString size}-network" { } ''
        ${pkgs.gzip}/bin/gunzip -c ${model} > bestNetwork
        ${converterPython}/bin/python ${./board_resize.py} bestNetwork ${toString size} resizedNetwork
        ${pkgs.gzip}/bin/gzip -c resizedNetwork > $out
      '';

  usedSizes = lib.unique (mapAttrsToList (name: variant: variant.size));

in mapAttrs
  (name: variant: convertNetwork models."${variant.model}" variant.size) cfg.variants
