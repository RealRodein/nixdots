# VFIO GPU passthrough – GTX 1050 Ti → Windows VM
# Host keeps RTX 3070 on nvidia + COSMIC.
#
# BEFORE FIRST BOOT:
#   Run `lspci -nn | grep -i nvidia` and confirm the PCI IDs match below.
#   Typical 1050 Ti IDs: 10de:1c82 (GPU) + 10de:0fb9 (HDMI audio).
#
# AFTER REBOOT, verify vfio-pci owns the 1050 Ti:
#   lspci -nnk | grep -A 3 "10de:1c82"
#   → Kernel driver in use: vfio-pci

{ config, lib, pkgs, ... }:

{
  # ── IOMMU + VFIO early binding ────────────────────────────────────
  # vfio-pci.ids= is processed during early PCI enumeration,
  # BEFORE any GPU driver can claim the device (this is the key fix).
  boot.kernelParams = [
    "amd_iommu=on"
    "iommu=pt"
    "pcie_acs_override=downstream,multifunction"
    "vfio-pci.ids=10de:1c82,10de:0fb9"
    "default_hugepagesz=2M"
    "hugepagesz=2M"
    "hugepages=256"
  ];

  # ── VFIO modules in initrd ──
  boot.initrd.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];

  # ── libvirt + QEMU ──
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  programs.virt-manager.enable = true;

  # ── User permissions ──
  users.users.rodein.extraGroups = [ "kvm" "libvirtd" ];
}
