{
  pkgs,
  machine,
  ...
}: {
  home.packages = with pkgs;
    [
      flutter
    ]
    ++ (
      if machine.linux
      then [pkgs.android-studio]
      else []
    );
}
