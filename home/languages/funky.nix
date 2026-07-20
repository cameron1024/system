{pkgs, ...}: {
  home.packages = with pkgs; [
    fstar
    elan # lean theorem prover

    ponyc # pony compiler
    pony-corral # pony package manager
  ];
}
