{
  description = "chula-flake checks";

  inputs = {
    chula.url = "path:..";
    nixpkgs.follows = "chula/nixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      chula,
      nixpkgs,
      sops-nix,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./tests/wifi.nix { inherit pkgs chula sops-nix; }
        // {
          formatting = pkgs.runCommand "formatting" { } ''
            cp -r --no-preserve=mode ${chula} src && cd src
            ${pkgs.lib.getExe chula.formatter.${system}} --ci
            touch $out
          '';
        }
      );
    };
}
