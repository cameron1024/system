{pkgs, ...}: {
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
  ];

  home.shellAliases = {
    "cg" = "cargo";
  };
}
