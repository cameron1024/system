final: prev: {
  cams-utils = {
    hyprland = {
      mkColor = hex: "rgb(${prev.lib.strings.removePrefix "#" hex})";
    };
  };

  everforest-gtk = prev.callPackage ./packages/everforest-gtk.nix {};
}
