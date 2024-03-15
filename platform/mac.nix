{
  inputs,
  overlays,
}: rec {
  system = "aarch64-darwin";

  pkgs = import inputs.nixpkgs {
    inherit system overlays;
    config = {allowUnfree = true;};
  };

  naersk = pkgs.callPackage inputs.naersk {};
  crane = inputs.crane.lib.${system};
}
