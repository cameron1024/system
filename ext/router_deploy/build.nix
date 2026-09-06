{
  lib,
  craneLib,
  proton-pass-cli,
}: let
  # Filters out everything not needed for a cargo build (readme, nix files,
  # etc.) so unrelated edits don't cause rebuilds.
  src = craneLib.cleanCargoSource ./.;

  commonArgs = {
    inherit src;
    strictDeps = true;

    # The pass-cli binary is baked into router_deploy at compile time via
    # env!("PASS_CLI_BIN"), which also pulls it into the runtime closure.
    nativeBuildInputs = [proton-pass-cli];
    env.PASS_CLI_BIN = lib.getExe proton-pass-cli;
  };

  # Dependencies are built as a separate derivation, so they are cached
  # across source changes.
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;
      meta.mainProgram = "router_deploy";
    })
