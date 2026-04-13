# Hardware configuration for QEMU/KVM Proxmox VM

{ config, lib, pkgs, ... }:

{
  imports = [];

  boot.initrd.availableKernelModules = [
    "ata_piix" "uhci_hcd" "ehci_pci" "ahci" "virtio_pci" "virtio_blk"
  ];
  boot.initrd.kernelModules = [ "virtio_net" "e1000" ];
  boot.kernelModules = [ "kvm-intel" ];

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "noatime" "nodiratime" "discard" ];
  };

  fileSystems."/boot" = {
    device = "/dev/sda2";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/sda3"; }
  ];

  # Virtio optimizations
  boot.loader.timeout = 0;
  boot.loader.grub.timeout = 0;
  boot.loader.grub.fsModuleConfig = "";
  
  # KVM Guest
  services.qemuGuest.enable = true;

  networking.usePredictableInterfaceNames = true;
}
