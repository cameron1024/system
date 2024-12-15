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

      bacon

      hyperfine

      evcxr
    ])
    ++ extras;

  home.shellAliases = {
    "cg" = "cargo";
  };
}
