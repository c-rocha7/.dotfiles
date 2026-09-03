{ self, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.myMpv;
  };
}
