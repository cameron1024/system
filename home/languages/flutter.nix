{
  pkgs,
  machine,
  ...
}: {
  home.packages = with pkgs;
    [
    ]
    ++ (
      if machine.linux
      then [pkgs.android-studio pkgs.flutter]
      else []
    );
}
