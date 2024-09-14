{
  pkgs,
  machine,
  ...
}: {
  home.packages = with pkgs;
    [
      mdcat
      slides
      jnv
    ]
    ++ (
      if machine.linux
      then [pkgs.tdf]
      else []
    );
}
