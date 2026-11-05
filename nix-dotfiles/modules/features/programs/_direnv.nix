{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs.unstable.direnv;

    nix-direnv = {
      enable = true;
    };
  };
}
