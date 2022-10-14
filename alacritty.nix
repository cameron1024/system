{ colors, device, font }:

{
  enable = true;
  settings = {
    font = {
      normal = { family = font; };
      size = device.fontSize;
    };

    env = {
      TERM = "xterm-256color";
      WINIT_X11_SCALE_FACTOR = "1.0";
    };

    scrolling = { history = 30000; };
    window = { decorations = "none"; };

    key_bindings = [
      { key = "F11"; action = "ToggleFullscreen"; }
    ];

    colors = colors.alacritty;
  };
}
