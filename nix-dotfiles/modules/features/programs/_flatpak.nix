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
    ];

    update.auto.enable = true;
    update.auto.onCalendar = "weekly";
  };
}
