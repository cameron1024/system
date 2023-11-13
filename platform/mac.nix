{ nixpkgs, ... } @ inputs:

rec {
  system = "aarch64-darwin";

  pkgs = import nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
  };

  naersk = pkgs.callPackage inputs.naersk {};
}

