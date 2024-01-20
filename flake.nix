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

      version = "0.0.1";
    in
      {
        packages = {
          emoji-drawing-web = pkgs.callPackage ./website/package.nix {inherit version;};
          emoji-drawing-server = pkgs.callPackage ./server/package.nix {inherit version;};
        };
        # TODO: Generate dev shell from packages.
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            flutter316
            sqlite
            nodejs_20
          ];
        };
      }
      // {
        overlays.default = _final: prev: {
          emoji-drawing-web = prev.callPackage ./website/package.nix {inherit version;};
          emoji-drawing-server = prev.callPackage ./server/package.nix {inherit version;};
        };
        nixosModules = {
          default = import ./module.nix self;
        };
      });
}
