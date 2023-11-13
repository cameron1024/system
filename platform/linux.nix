{ nixpkgs, ... } @ inputs:

rec {
  system = "x86_64-linux";

  pkgs = import nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
  };

  naersk = pkgs.callPackage inputs.naersk {};
}

