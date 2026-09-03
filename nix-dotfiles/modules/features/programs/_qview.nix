{ pkgs, ... }:

{
  home.packages = with pkgs;
    [
      qview
    ];
}
