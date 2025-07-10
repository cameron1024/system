{
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      mdcat
      slides
      jnv
      presenterm
    ]
    ++ (
      if pkgs.stdenv.isLinux
      then [pkgs.tdf]
      else []
    );

  xdg.configFile."presenterm/config.yaml".text = ''
    defaults:
      image_protocol: kitty-local
  '';
}
