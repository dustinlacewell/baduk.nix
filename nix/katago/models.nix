{ pkgs, lib, cfg }:

with lib;

let
  fetchModel = model:
    let
      url =
        if (hasPrefix "http://" model.url) then model.url else
          "${cfg.releaseUrl}/${model.url}";
      args = { inherit url; inherit (model) sha256; };
      fetcher =
        if hasSuffix ".zip" model.url then
            (args: pkgs.fetchzip (args // {
              name = "model.bin.gz";
              extraPostFetch = ''
                mv $out/model.bin.gz $TMPDIR
                rm -fr $out
                mv $TMPDIR/model.bin.gz $out
              '';
            }))
        else
          pkgs.fetchurl;
    in
      fetcher (builtins.trace (generators.toPretty {} args) args);

in mapAttrs (name: model: fetchModel model) cfg.models
