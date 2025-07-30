# Not a nixos module - imported and called as a regular function
{inputs, system}: rec {
  firmware = inputs.zmk.legacyPackages.${system}.buildSplitKeyboard {
    name = "firmware";
    src = ./.;
    board = "nice_nano_v2";
    shield = "corne_%PART% nice_view_adapter nice_view";
    zephyrDepsHash = "sha256-iWWZVmLZUTKoqzkI0K3l2f37kslEX0Mnah2AB+idZWg=";
  };

  flash = inputs.zmk.packages.${system}.flash.override { inherit firmware; };
  update = inputs.zmk.packages.${system}.update;
}
