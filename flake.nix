{
  description = "Emoji Drawing flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages = {
        emoji-drawing-web = pkgs.callPackage ./website/package.nix {};
        emoji-drawing-server = pkgs.callPackage ./server/package.nix {};
      };
      # TODO: Generate dev shell from packages.
      # devShell = pkgs.mkShell {
      # };
    })
    // {
      overlays.default = _final: prev: {
        emoji-drawing-web = prev.callPackage ./website/package.nix {};
        emoji-drawing-server = prev.callPackage ./server/package.nix {};
      };
      nixosModules = {
        default = import ./module.nix self;
      };
    };
}
