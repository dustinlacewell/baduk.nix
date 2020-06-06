{ pkgs, lib, cfg, models }:

with builtins;
with lib;

let
  katajigo = import ./katajigo { inherit pkgs; };
  createConfig = name: { config, ... }:
    let
      filterNull = attrs: filterAttrs (k: v: v != null && v != "") attrs;
      convertBool = attrs: mapAttrs (k: v: if isBool v then boolToString v else v) attrs;
      clean = attrs: filterNull (convertBool attrs);
      coreDefaults = clean (import ./option-defaults.nix);
      userDefaults = clean (removeAttrs cfg.defaults [ "extraConfig" ]);
      userConfig = clean (removeAttrs config [ "extraConfig" ]);
      mergedConfig = coreDefaults // userDefaults // userConfig;
      lines = mapAttrsToList (key: value: "${key} = ${toString value}") mergedConfig;
      extraConfig = cfg.defaults.extraConfig + config.extraConfig;
      text = concatStrings (intersperse "\n" (lines ++ [ extraConfig  ]));
    in
      pkgs.writeTextFile {
        inherit text;
        name = "katago-config-${name}";
      };

  createWrapper = name: { model, config, jigo ? false }@args:
    let
      kataBin =
        if jigo then
          "${katajigo.package}/bin/katajigo"
        else
          "${pkgs.katago}/bin/katago";
      modelPkg = models."${model}";
      config = createConfig name args;
      namePostfix = if jigo then "Jigo" else "Go";
    in
      pkgs.writeScriptBin "Kata${namePostfix}-${name}" ''
        #!${pkgs.stdenv.shell}
        ${kataBin} gtp -config ${config} -model ${modelPkg} $@
      '';

in mapAttrs (name: variant: createWrapper name variant) cfg.variants
