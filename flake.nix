{
    description = "The Open Food Network is an online marketplace for local food.";

    inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      
      flake-utils = {
        url = "github:numtide/flake-utils";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };

    outputs = { self, nixpkgs, flake-utils }:
    let
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      outputs = flake-utils.lib.eachSystem systems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.ruby
            pkgs.bundler
            pkgs.postgresql_16_jit
            pkgs.nodejs_21
            pkgs.redis
            pkgs.shared-mime-info
            pkgs.libyaml
            pkgs.yarn
          ] ;
          shellHook = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
            export CPATH=$(xcrun --sdk macosx --show-sdk-path)/usr/include

          '';
        };
      });
    in outputs // {};

    nixConfig = {};
}
