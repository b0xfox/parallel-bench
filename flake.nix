{
  description = "Flake for parallel Blockbench packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      overlays.default = final: prev: {
        blockbench4 = final.callPackage ./pkgs/blockbench4 { };
        blockbench5 = final.callPackage ./pkgs/blockbench5 { };
      };

      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs) blockbench4 blockbench5;
        }
      );
    };
}
