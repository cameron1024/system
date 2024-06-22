{inputs, ...}: {
  thinkpad = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      stateVersion = "22.05";
      boot = "/boot";
      hostname = "thinkchad";
    };
    modules = [./common.nix ./hardware/thinkpad.nix];
  };
}
