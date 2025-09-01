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
  [
    # (final: prev: {niri = inputs.niri.packages.${prev.system}.niri.override {
    #   doCheck = false;
    # };})
  ]
  # ++ (optionals (optimizations && arch != null [
  #   (import ./gcc_optimiztions.nix {inherit inputs; })
  # ]))
  ++ (optionals (optimizations && arch != null) [
    (import inputs.rust-overlay)
    # (import ./rust_optimizations.nix {
    #   inherit inputs arch;
    #   packageList = [
    #     "rust-analyzer"
    #     "starship"
    #     "ripgrep"
    #     "eza"
    #     "nushell"
    #     "fish"
    #     "television"
    #   ];
    # })
  ])
  ++ [
    inputs.nixgl.overlay
    (import ./utils.nix)
  ]
