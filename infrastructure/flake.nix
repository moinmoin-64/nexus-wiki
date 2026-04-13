{
  description = "Project Nexus - Bootable NixOS Appliance";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    {
      packages.x86_64-linux = 
        let
          nixos = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
              {
                isoImage.volumeID = "NEXUS-0.1.0";
                isoImage.makeEfiBootable = true;
                isoImage.makeUsbBootable = true;
                networking.hostName = "nexus";
              }
            ];
          };
        in
        {
          iso = nixos.config.system.build.isoImage;
          default = nixos.config.system.build.isoImage;
        };
    };
}
