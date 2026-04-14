{ lib, pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # Use latest boot
  boot.loader.systemd-boot.enable = lib.mkForce true;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce true;

  # Network
  networking.hostName = "nexus-iso";
  networking.networkmanager.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    nano
    htop
    tmux
    nodejs
    postgresql
    redis
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # ISO settings
  isoImage.volumeID = "NEXUS-0.1.0";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  system.stateVersion = "24.05";
}
