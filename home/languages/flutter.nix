{
  pkgs,
  machine,
  ...
}: {
  home.shellAliases = {
    "fpg" = "flutter pub get";
    "fpb" = "flutter pub run build_runner build";
    "fr" = "flutter run";
  };

  home.packages = with pkgs;
    [
    ]
    ++ (
      if machine.linux
      then [pkgs.android-studio pkgs.flutter]
      else []
    );
}
