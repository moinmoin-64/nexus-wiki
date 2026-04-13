{
  description = "Project Nexus - Dedicated TUI Server Appliance";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators }:
    flake-utils.lib.eachDefaultSystem (system: {
      packages = {
        # NixOS Installer ISO
        iso = (nixos-generators.nixosGenerate {
          inherit system;
          modules = [ self.nixosModules.nexus ];
          format = "iso";
        }).config.system.build.isoImage;

        # QCOW2 for Proxmox/KVM
        qcow2 = (nixos-generators.nixosGenerate {
          inherit system;
          modules = [ self.nixosModules.nexus ];
          format = "qcow";
        }).config.system.build.qcow2Image;
      };

      defaultPackage = self.packages.${system}.iso;
    }) // {
      nixosModules.nexus = ./configuration.nix;
      nixosConfigurations.nexus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./configuration.nix ./hardware-configuration.nix ];
      };
    };
}
