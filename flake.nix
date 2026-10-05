{
  description = "NixOS modules for Chulalongkorn University";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Checks live in ./dev so their inputs stay out of consumers' lock files.
  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      nixosModules = {
        default = ./modules;
        wifi = ./modules/wifi;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
