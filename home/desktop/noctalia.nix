{pkgs, ...}: {
  programs.noctalia-shell = {
    enable = true;
    colors = {
      mError = "#e67e80";
      mOnError = "#272e33";
      mOnPrimary = "#272e33";
      mOnSecondary = "#272e33";
      mOnSurface = "#859289";
      mOnSurfaceVariant = "#7a8478";
      mOnTertiary = "#272e33";
      mOnHover = "#d3c6aa";
      mOutline = "#374145";
      mPrimary = "#a7c080";
      mSecondary = "#83c092";
      mShadow = "#000000";
      mSurface = "#272e33";
      mHover = "#2e383c";
      mSurfaceVariant = "#1e2326";
      mTertiary = "#d699b6";
    };

    settings = {
      general.animationSpeed = 2.0;

      ui.fontDefault = "Josefin Sans";
      ui.fontFixed = "FiraCode Nerd Font";

      location.name = "London";

      dock.enabled = false;

      wallpaper.enabled = true;
      wallpaper.directory = pkgs.wallpapers.all;

      appLauncher.position = "topLeft";

      # controlCenter.cards = [
      #   {
      #     enabled = true;
      #     id = "profile-card";
      #   }
      #   {
      #     enabled = true;
      #     id = "shortcuts-card";
      #   }
      #   {
      #     enabled = true;
      #     id = "audio-card";
      #   }
      #   {
      #     enabled = true;
      #     id = "weather-card";
      #   }
      #   {
      #     enabled = true;
      #     id = "media-sysmon-card";
      #   }
      # ];
    };
  };
}
