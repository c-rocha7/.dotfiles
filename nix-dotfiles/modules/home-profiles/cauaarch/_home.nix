{ ... }:

{
  home = {
    username = "cauaarch";
    homeDirectory = "/home/cauaarch";
    stateVersion = "26.05";

    packages = [ ];
  };

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
