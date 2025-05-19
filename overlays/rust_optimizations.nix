{
  inputs,
  arch,
  packageList,
}: let
  pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  optimizePackage = name:
    inputs.nixpkgs.lib.customisation.overrideDerivation pkgs.${name} (oldAttrs: {
      "RUSTFLAGS" = "-Ctarget-cpu=${arch}";
    });
  f = name: {
    inherit name;
    value = optimizePackage name;
  };
  optimizedPackages = map f packageList;
in
  if arch == null
  then (prev: final: prev)
  else (prev: final: builtins.listToAttrs optimizedPackages)
