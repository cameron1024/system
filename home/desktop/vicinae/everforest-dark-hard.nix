{
  meta = {
    # these are required
    version = 1;
    name = "Everforest Dark Hard";
    description = "Everforest Dark Hard";
    variant = "dark";
    inherits = "vicinae-dark";
  };

  colors = {
    core = {
      accent = "#a7c080";
      accent_foreground = "#272e33";
      background = "#272e33";
      foreground = "#d3c6aa";
      secondary_background = "#2e383c";
      border = "#374145";
    };

    main_window = {
      border = "#374145";
    };

    settings_window = {
      border = "#374145";
    };

    accents = {
      blue = "#7fbbb3";
      cyan = "#83c092";
      green = "#a7c080";
      magenta = "#d699b6";
      orange = "#e69875";
      purple = "#d699b6";
      red = "#e67e80";
      yellow = "#dbbc7f";
    };

    text = {
      default = "#d3c6aa";
      muted = "#859289";
      danger = "#e67e80";
      success = "#a7c080";
      placeholder = "#7a8478";
      selection = {
        background = "#a7c080";
        foreground = "#272e33";
      };
      links = {
        default = "#7fbbb3";
        visited = "#d699b6";
      };
    };

    input = {
      border = "#374145";
      border_focus = "#a7c080";
      border_error = "#e67e80";
    };

    button = {
      primary = {
        background = "#374145";
        foreground = "#d3c6aa";
        hover = {
          background = "#3d484d";
        };
        focus = {
          outline = "#a7c080";
        };
      };
    };

    list = {
      item = {
        hover = {
          foreground = "#d3c6aa";
          secondary_foreground = "#859289";
        };
        selection = {
          background = "#374145";
          foreground = "#d3c6aa";
          secondary_background = "#2e383c";
          secondary_foreground = "#859289";
        };
      };
    };

    grid = {
      item = {
        background = "#2e383c";
        hover = {
          outline = "#a7c080";
        };
        selection = {
          outline = "#a7c080";
        };
      };
    };

    scrollbars = {
      background = "#374145";
    };

    loading = {
      bar = "#a7c080";
      spinner = "#a7c080";
    };
  };
}
