{ self, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.myYazi;
  };
}
