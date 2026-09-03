{ ... }:

{
  flake.homeModules = {
    /*---- Programs ----*/
    # flatpak = ./features/programs/_flatpak.nix;
    # nil = ./features/programs/_nil.nix;
    # nixd = ./features/programs/_nixd.nix;
    # nixpkgs-fmt = ./features/programs/_nixpkgs-fmt.nix;
    # obsidian = ./features/programs/_obsidian.nix;
    # vesktop = ./features/programs/_vesktop.nix;
    zen = ./features/programs/_zen.nix;

    /*---- Wrappers ----*/
    # btop = ./features/wrappers/btop/_btop.nix;
    # vim = ./features/wrappers/vim/_vim.nix;
    # yazi = ./features/wrappers/yazi/_yazi.nix;
  };
}
