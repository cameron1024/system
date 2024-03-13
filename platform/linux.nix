{
  inputs,
  overlays,
}: rec {
  system = "x86_64-linux";

  pkgs = import inputs.nixpkgs {
    inherit system overlays;
    config = {allowUnfree = true;};
  };

  naersk = pkgs.callPackage inputs.naersk {};
}
