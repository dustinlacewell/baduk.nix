{ pkgs, cfg, lib }:

pkgs.appimageTools.wrapType2 rec {
  name = "sabaki-${cfg.version}";
  src = pkgs.fetchurl { inherit (cfg) url sha256; };
  multiPkgs = null; # no 32bit needed
  extraPkgs = pkgs.appimageTools.defaultFhsEnvArgs.multiPkgs;
  extraInstallCommands = "mv $out/bin/{${name},sabaki}";
  profile = ''
    export LC_ALL=C.UTF-8
    export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
  '';
}
