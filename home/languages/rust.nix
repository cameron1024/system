{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    rustup

    cargo-info
    cargo-lambda
    cargo-rr
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
    inputs.binsider.packages.${pkgs.system}.default
  ];

  home.shellAliases = {
    "cg" = "cargo";
  };
}
