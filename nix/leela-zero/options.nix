{ pkgs, lib, cfg }:

with lib;

let
  modelOption = types.submodule {
    options = {
      url = mkOption { type = types.str; };
      sha256 = mkOption { type = types.str; };
    };
  };

  variantOption = types.submodule {
    options = {
      model = mkOption {
        type = types.str;
        default = "best";
      };

      size = mkOption {
        type = types.ints.positive;
        default = 19;
      };

      visits = mkOption {
        type = types.ints.positive;
        default = 100;
      };

      playouts = mkOption {
        type = types.ints.positive;
        default = 100;
      };
    };
  };

in {
  enable = mkEnableOption "leela-zero";

  models = mkOption {
    type = types.attrsOf modelOption;
    default = {
      best = {
        url = "http://zero.sjeng.org/best-network";
        sha256 = "1wwhlfhi21pkcws8s1skbrn8ma24i38nmh80d4bj5fv7lmnpsrjl";
      };
    };
  };

  variants = mkOption {
    type = types.attrsOf variantOption;
    default = {
      "19x19" = {
        model = "best";
        size = 19;
      };
      "13x13" = {
        model = "best";
        size = 13;
      };
      "9x9" = {
        model = "best";
        size = 9;
      };
    };
  };
}
