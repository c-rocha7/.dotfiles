{ inputs, ... }:

{
  perSystem = { system, ... }:
    let
      pkgsIsolated = import inputs.nixpkgs
        {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (final: prev:
              {
                unstable = import inputs.nixpkgs-unstable
                  {
                    inherit system;
                    config.allowUnfree = true;
                  };
              }
            )
          ];
        };
    in
    {
      legacyPackages = pkgsIsolated;
      _module.args.pkgs = pkgsIsolated;
    };
}
