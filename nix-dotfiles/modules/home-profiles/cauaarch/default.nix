{ inputs, self, ... }:

{
  flake.homeConfigurations."cauaarch" = inputs.home-manager.lib.homeManagerConfiguration
    {
      pkgs = self.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs self; };

      modules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak

        { imports = builtins.attrValues (self.homeModules or { }); }

        ./_home.nix
      ];
    };
}
