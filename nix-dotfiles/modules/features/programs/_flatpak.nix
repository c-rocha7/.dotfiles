{ ... }:

{
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "com.github.tchx84.Flatseal"
      "com.vysp3r.ProtonPlus"
      "io.github.flattool.Warehouse"
      "io.github.Foldex.AdwSteamGtk"
      "io.github.kolunmi.Bazaar"
      "org.gnome.Calculator"
      "org.gnome.Calendar"
      "org.gnome.TextEditor"
      "org.gnome.clocks"
      "io.missioncenter.MissionCenter"
      "org.ferdium.Ferdium"
      "com.spotify.Client"
      "org.kde.okular"

      # Navicat Premium 18 (repositório próprio do Navicat; o runtime vem do Flathub).
      # Se o Navicat atualizar o .flatpakref, o hash muda: nix-prefetch-url <url>
      {
        flatpakref = "https://dn.navicat.com/flatpak/flatpakref/navicat18/com.navicat.premium.en.flatpakref";
        sha256 = "1lj2xj6ag2ppdp9wg7nl3payac7ykykj86bd6ynyg7izzyjscvi4";
      }
    ];

    update.auto.enable = true;
    update.auto.onCalendar = "weekly";
  };
}
