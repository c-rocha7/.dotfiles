{ ... }:

{
  flake.homeModules = {
    /*---- Programs ----*/
    devenv = ./features/programs/_devenv.nix;
    direnv = ./features/programs/_direnv.nix;
    flatpak = ./features/programs/_flatpak.nix;
    nil = ./features/programs/_nil.nix;
    nixd = ./features/programs/_nixd.nix;
    nixpkgs-fmt = ./features/programs/_nixpkgs-fmt.nix;
    obsidian = ./features/programs/_obsidian.nix;
    qview = ./features/programs/_qview.nix;
    tealdeer = ./features/programs/_tealdeer.nix;
    vesktop = ./features/programs/_vesktop.nix;
    zen = ./features/programs/_zen.nix;

    /*---- Wrappers ----*/
    btop = ./features/wrappers/btop/_btop.nix;
    fastfetch = ./features/wrappers/fastfetch/_fastfetch.nix;
    mpv = ./features/wrappers/mpv/_mpv.nix;
    vim = ./features/wrappers/vim/_vim.nix;
    yazi = ./features/wrappers/yazi/_yazi.nix;
  };
}
