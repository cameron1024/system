{
  lib,
  machine,
  ...
}: {
  config = lib.mkIf (!machine.linux) {
    home.file."Library/KeyBindings/DefaultKeyBinding.dict".source = ./override_option_bindings;
  };
}
