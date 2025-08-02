{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [inputs.nix-ai-tools.packages.${pkgs.system}.crush];
}
