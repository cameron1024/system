{
  pkgs,
  inputs,
  machine,
  ...
}: let
  extras =
    if machine.linux
    then [
      pkgs.cargo-rr
      inputs.binsider.packages.${pkgs.system}.default
    ]
    else [];
in {
  home.packages =
    (with pkgs; [
      rustup

      cargo-info
      cargo-wipe
      cargo-rdme
      cargo-msrv
      cargo-fuzz
      cargo-dist
      cargo-udeps
      cargo-bloat
      cargo-wizard
      cargo-nextest
      cargo-spellcheck
      cargo-expand
      cargo-release

      bacon

      hyperfine
    ])
    ++ extras;

  home.shellAliases = {
    "cg" = "cargo";
  };
}
