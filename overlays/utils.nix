final: prev: {
  cams-utils = {
    hyprland = {
      mkColor = hex: "rgb(${prev.lib.strings.removePrefix "#" hex})";
    };
  };
}
