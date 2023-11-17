{ isDarwin, ... }:

{
  imports = [
    ./configuration/shared.nix

    (if isDarwin then ./configuration/mac.nix else ./configuration/linux.nix)
  ];
}
