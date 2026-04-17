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

    };
  };
}
