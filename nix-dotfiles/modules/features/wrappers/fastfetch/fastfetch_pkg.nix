{ inputs, ... }:

{
  perSystem = { pkgs, lib, ... }:
    {
      # Fastfetch com a configuração embutida (passada via --config).
      # - config.json: módulos e layout (edite este arquivo normalmente)
      # - arch.txt: logo usado no lugar do logo padrão
      packages.myFastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
        inherit pkgs;

        settings = lib.recursiveUpdate (lib.importJSON ./config.json) {
          logo = {
            type = "file";
            source = "${./arch.txt}";
          };
        };
      };
    };
}
