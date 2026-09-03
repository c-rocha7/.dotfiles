{ inputs, ... }:

{
  perSystem = { pkgs, ... }:
    {
      packages.myMpv = inputs.wrapper-modules.wrappers.mpv.wrap {
        inherit pkgs;
      };
    };
}
