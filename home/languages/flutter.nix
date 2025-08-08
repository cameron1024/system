{
  pkgs,
  lib,
  nixosConfig,
  ...
}: {
  home.shellAliases = {
    "fpg" = "flutter pub get";
    "fpb" = "flutter pub run build_runner build";
    "fr" = "flutter run";
  };

  home.packages = with pkgs;
    []
    ++ (lib.optionals (nixosConfig != null) [
      flutter
    ]);
}
