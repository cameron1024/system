{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
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
      rusty-man

      hyperfine

      evcxr

      mdbook

      python3 # needed for cargo-kani
    ]
    ++ (lib.optionals stdenv.isLinux [
      cargo-rr
      binsider
    ]);

  home.sessionVariables = {
    "RUST_BACKTRACE" = 1;
  };

  home.shellAliases = {
    "cg" = "cargo";
    "cnt" = "cargo nextest run";
  };
}
