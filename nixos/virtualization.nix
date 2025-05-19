{
  virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  boot.kernelParams = ["kvm.enable_virt_at_load=0"];
  users.extraGroups.vboxusers.members = [ "cameron" ];
}
