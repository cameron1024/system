{
  pkgs,
  lib,
  isDarwin,
  ...
}:
with lib; {
  home.packages = with pkgs;
    [
      rustup

      bacon

      cargo-cache
      cargo-nextest
      cargo-udeps
      cargo-edit
      cargo-bloat
      cargo-duplicates
      cargo-info
      cargo-outdated

      evcxr
    ]
    ++ optionals (!isDarwin) [
      gcc
      llvmPackages.bintools-unwrapped
      cmake
      ninja
    ];

  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];

  programs.fish.shellAbbrs = {
    r = "evcxr";
    cg = "cargo";
    nt = "cargo nextest run";
  };

  programs.nushell.shellAliases = {
    r = "evcxr";
    cg = "cargo";
    nt = "cargo nextest run";
  };
}
