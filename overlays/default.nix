{
  inputs,
  arch ? null,
  optimizations ? true,
}: let
  optionals = cond: list:
    if cond
    then list
    else [];
in
  []
  ++ (optionals (optimizations && arch != null) [
    (import inputs.rust-overlay)
    (import ./rust_optimizations.nix {
      inherit inputs arch;
      packageList = [
        "rust-analyzer"
        "starship"
        "ripgrep"
        "eza"
        "nushell"
        "fish"
        "television"
      ];
    })
  ])
  ++ [
    inputs.nixgl.overlay
    (import ./utils.nix)
  ]
