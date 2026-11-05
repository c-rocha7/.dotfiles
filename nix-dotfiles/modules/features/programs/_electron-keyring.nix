# Apps Electron fora do GNOME/KDE (ex.: Hyprland) não detectam o chaveiro e guardam
# senhas/tokens com uma chave fixa ("basic"). Este embrulho passa
# --password-store=gnome-libsecret (gnome-keyring, desbloqueado no login pelo PAM do ly)
# sem recompilar o pacote.
#
# Uso:  package = import ./_electron-keyring.nix pkgs pkgs.vesktop "vesktop";
pkgs: pkg: bin:

let
  wrap = p: pkgs.symlinkJoin {
    name = "${p.pname or p.name}-keyring";
    inherit (p) version meta;
    paths = [ p ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${bin} --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
# "override" repassado ao pacote original (o módulo do vesktop no home-manager usa
# package.override { withSystemVencord = ...; }) e embrulhado de novo.
wrap pkg // { override = args: wrap (pkg.override args); }
