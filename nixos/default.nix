{inputs, ...}: {
  thinkpad = inputs.nixpkgs.lib.nixosSysem {
    system = "x86_64-linux";
    specialArgs = {
      stateVersion = "22.05";
      boot = "/boot";
      hostname = "thinkchad";
    };
    imports = [./common.nix ./hardware/thinkpad.nix];
  };
}
