{
  pkgs,
  lib,
  ...
}: {
  home.shellAliases = {
    "fpg" = "flutter pub get";
    "fpb" = "flutter pub run build_runner build";
    "fr" = "flutter run";
  };

  home.packages = with pkgs;
    []
    ++ (lib.optionals stdenv.isLinux [
      # android-studio
      # flutter
    ]);
}
