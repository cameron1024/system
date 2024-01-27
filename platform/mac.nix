{ nixpkgs, ... } @ inputs:

rec {
  system = "aarch64-darwin";

  pkgs = import nixpkgs {
    inherit system;
    config = { allowUnfree = true; };
    overlays = [
      inputs.neovim-nightly-overlay.overlay
    ];
  };

  naersk = pkgs.callPackage inputs.naersk {};
}

