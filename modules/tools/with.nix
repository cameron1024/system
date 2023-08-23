{ pkgs, ... }:
let
  withScript = pkgs.writeShellScriptBin "with" ''
    set -x

    if [ $# -eq 0 ]; then
      >&2 echo "No arguments provided"
      exit 1
    fi

    nix-shell -p $argv --command "fish"
  '';
in
{
  environment.systemPackages = [ withScript ];
}
