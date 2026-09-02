{
  description = "Mesa-git builds";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mesa-src = {
      url = "gitlab:mesa/mesa?host=gitlab.freedesktop.org&ref=main";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    mesa-src,
  }: {
    overlays.default = import ./overlay.nix {inherit mesa-src;};

    nixosModules.default = {...}: {
      nixpkgs.overlays = [self.overlays.default];
    };

    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [self.overlays.default];
      };
    in {inherit (pkgs) mesa_git mesa32_git;};
  };
}
