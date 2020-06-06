{ pkgs, lib, cfg }:

with lib;

{
  enable = mkEnableOption "gnugo";
  sabakiLevels = mkOption {
    type = types.listOf (types.enum [1 2 3 4 5 6 7 8 9 10]);
    default = [1 5 10];
  };
}
