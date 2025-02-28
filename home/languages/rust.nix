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
      pkgs.binsider
    ]
    else [];
in {
  home.packages =
    (with pkgs; [
      rustup

      cargo-info
      cargo-insta
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
      cargo-flamegraph

      bacon

      hyperfine

      evcxr

      python3 # needed for cargo-kani
    ])
    ++ extras;

  home.sessionVariables = {
    "RUST_BACKTRACE" = 1;
  };

  home.shellAliases = {
    "cg" = "cargo";
  };
}
