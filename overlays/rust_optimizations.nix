{
  inputs,
  arch,
  packageList,
}: let
  pkgs = import inputs.nixpkgs {system = "x86_64-linux";};
  optimizePackage = {
    name,
    prev,
  }:
    inputs.nixpkgs.lib.customisation.overrideDerivation pkgs.${name} (oldAttrs: {
      # recent nightly is important for avx512 support
      cargo = prev.rust-bin.nightly.latest.default;
      rustc = prev.rust-bin.nightly.latest.default;
      "RUSTFLAGS" = "-Ctarget-cpu=${arch}";
    });
  f = prev: name: {
    inherit name;
    value = optimizePackage {inherit name prev;};
  };
  optimizedPackages = prev: map (f prev) packageList;
in
  if arch == null
  then (prev: final: prev)
  else (prev: final: builtins.listToAttrs (optimizedPackages prev))
