{
  inputs,
  arch,
  packageList,
}: let
  optimizedNixpkgs = import inputs.nixpkgs {
    localSystem = {
      gcc.arch = arch;
      gcc.tune = arch;
      system = "x86_64-linux";
    };
  };
  f = name: {
    inherit name;
    value = optimizedNixpkgs.${name};
  };
  optimizedPackages = map f packageList;
in
  if arch == null
  then (prev: final: prev)
  else (prev: final: builtins.listToAttrs optimizedPackages)
