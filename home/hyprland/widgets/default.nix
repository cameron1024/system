{
  pkgs,
  inputs,
  machine,
  lib,
  ...
}: let
  astal = inputs.astal;
  package = astal.lib.mkLuaPackage {
    inherit pkgs;
    name = "my-shell";
    src = ./my-shell;
  };
in {
  config =
    lib.mkIf machine.linux {
      home.packages = [
        inputs.astal.packages.${pkgs.system}.default
        package
      ];

    };
}
