{pkgs, ...}: {
  home.packages = with pkgs; [
    fstar
    elan # lean theorem prover
  ];
}
