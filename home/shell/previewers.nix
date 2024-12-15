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
      presenterm
    ]
    ++ (
      if machine.linux
      then [pkgs.tdf]
      else []
    );
}
