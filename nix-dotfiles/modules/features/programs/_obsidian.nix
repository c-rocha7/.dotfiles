{ pkgs, ... }:

{
  programs.obsidian = {
    enable = true;
    # Dados sensíveis guardados no chaveiro (ver _electron-keyring.nix)
    package = import ./_electron-keyring.nix pkgs pkgs.obsidian "obsidian";
  };
}
