{
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (pkgs.stdenv.isDarwin) {
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".source = ./override_option_bindings;
  };
}
