# parallel-bench

A Nix flake for packaging multiple [Blockbench](https://github.com/JannisX11/blockbench) packages and enabling parallel usage.

This includes versions:
- Blockbench 4 (4.12.4)
- Blockbench 5 (5.1.4)

## Flake Usage Example
```nix
{
  description = "My flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    parallel-bench.url = "github:b0xfox/parallel-bench";
  };

  outputs =
    { self, nixpkgs, parallel-bench, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ parallel-bench.overlays.default ];
      };
    in
    {
      nixosConfigurations = {
        <your hostname> = nixpkgs.lib.nixosSystem {
          inherit pkgs;
          inherit inputs;
          inherit system;
          modules = [ ./configuration.nix ];
        };
      };
    };
}

```

The overlay will allow you to add the packages to either your enviroment.systemPackages or home.packages just like any other packages
```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    blockbench4
    blockbench5
  ];
}
```

Alternatively, you can also add the exposed packages directly
```nix
{ inputs, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.parallel-bench.packages.${system}.blockbench4
    inputs.parallel-bench.packages.${system}.blockbench5
  ];
}
```

This is not an official Blockbench resource.
