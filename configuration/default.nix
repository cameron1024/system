{ isDarwin, ... }:

let
  platformSpecific = if isDarwin then ./mac.nix else ./linux.nix;
in

{
  imports = [
    ./shared
    platformSpecific
  ];
}
