{ pkgs, cfg, lib }:

with lib;

let
  engineOption = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      path = mkOption { type = types.str; };
      args = mkOption { type = types.str; default = ""; };
    };
  };

in {
  enable = mkEnableOption "sabaki";

  version = mkOption {
    type = types.str;
    default = "0.51.1";
  };

  url = mkOption {
    type = types.str;
    default =
      "https://github.com/SabakiHQ/Sabaki/releases/download/${cfg.version}/sabaki-v${cfg.version}-linux-x64.AppImage";
  };

  sha256 = mkOption {
    type = types.str;
    default = "0k4h9ncxi7rw1c1glhhivsf7wnrprl2x6s6zrk06v36a0gi4y5h8";
  };

  engines = mkOption { type = types.listOf engineOption; };
}
