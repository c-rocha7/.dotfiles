{ self, pkgs, ... }:

{
  # home.packages = [
  #   self.packages.${pkgs.stdenv.hostPlatform.system}.myBtop
  # ];

  programs.btop = {
    enable = true;
    package = self.packages.${pkgs.stdenv.hostPlatform.system}.myBtop;
  };
}
