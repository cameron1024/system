{inputs, ...}: {
  thinkpad = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./common.nix
      ./hardware/thinkpad.nix
      {machine = import ./machines/thinkpad.nix;}
    ];
  };
}
