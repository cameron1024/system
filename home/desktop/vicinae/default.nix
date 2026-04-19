{inputs, ...}: {
  imports = [inputs.vicinae.homeManagerModules.default];
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };

    settings = {
      close_on_focus_lost = true;
      pop_to_root_on_close = true;
      telemetry.system_info = false;
      font.normal.family = "Josefin Sans";
      launcher_window.layer_shell.layer = "overlay";

      keybinds = {
        "action.copy" = "return";
      };
      theme = {
        dark = {name = "everforest-dark-hard";};
        light = {name = "everforest-dark-hard";};
      };
    };

    themes = {
      everforest-dark-hard = import ./everforest-dark-hard.nix;
    };
  };
}
